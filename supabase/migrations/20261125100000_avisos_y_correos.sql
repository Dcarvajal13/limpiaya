-- =============================================================================
-- HU-50 · Campana de avisos en la app
-- HU-49 · Avisos por correo (postulación, elección, recordatorio 24 h, cancelación)
--
-- Crea:
--   1. `public.avisos` con RLS y Realtime para la campana en la app.
--   2. `public.perfiles.avisos_correo` para que cada usuario controle sus
--      avisos por correo (solo mediante RPC, sin abrir más columnas al grant).
--   3. `public.cola_correos` (patrón outbox) donde los triggers registran los
--      correos que un proveedor externo (Edge Function + Resend/SMTP) despacha.
--   4. Triggers en `postulaciones` y `solicitudes` para generar avisos y
--      correos automáticamente ante cada evento clave.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Preferencia de avisos por correo en perfiles (HU-49)
-- ---------------------------------------------------------------------------
alter table public.perfiles
  add column if not exists avisos_correo boolean not null default true;

comment on column public.perfiles.avisos_correo is
  'HU-49: si el usuario desea recibir avisos por correo electrónico.';

create or replace function public.actualizar_avisos_correo(p_activo boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (select auth.uid());
begin
  if v_id is null then
    raise exception 'Inicia sesión para cambiar esta preferencia';
  end if;

  update public.perfiles
     set avisos_correo = coalesce(p_activo, true)
   where id = v_id;
end;
$$;

revoke execute on function public.actualizar_avisos_correo(boolean) from public, anon;
grant execute on function public.actualizar_avisos_correo(boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Tabla de avisos en la app (HU-50)
-- ---------------------------------------------------------------------------
create table if not exists public.avisos (
  id          uuid primary key default gen_random_uuid(),
  usuario_id  uuid not null references public.perfiles(id) on delete cascade,
  tipo        text not null
              check (tipo in ('postulacion', 'eleccion', 'cancelacion', 'completada', 'recordatorio', 'cuenta', 'sistema')),
  titulo      text not null check (char_length(trim(titulo)) between 1 and 140),
  mensaje     text not null check (char_length(trim(mensaje)) between 1 and 500),
  ruta        text,
  leido_en    timestamptz,
  created_at  timestamptz not null default now()
);

create index if not exists avisos_usuario_idx
  on public.avisos (usuario_id, created_at desc);

create index if not exists avisos_no_leidos_idx
  on public.avisos (usuario_id)
  where leido_en is null;

alter table public.avisos enable row level security;

revoke all on public.avisos from anon, authenticated;
grant select on public.avisos to authenticated;
grant update (leido_en) on public.avisos to authenticated;

create policy "avisos: leer los míos" on public.avisos
  for select to authenticated
  using (usuario_id = (select auth.uid()));

create policy "avisos: marcar los míos como leídos" on public.avisos
  for update to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

do $$
begin
  if not exists (
    select 1
      from pg_publication_tables
     where pubname = 'supabase_realtime'
       and schemaname = 'public'
       and tablename = 'avisos'
  ) then
    alter publication supabase_realtime add table public.avisos;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Cola de correos transaccionales (HU-49)
-- ---------------------------------------------------------------------------
create table if not exists public.cola_correos (
  id              uuid primary key default gen_random_uuid(),
  usuario_id      uuid not null references public.perfiles(id) on delete cascade,
  solicitud_id    uuid references public.solicitudes(id) on delete set null,
  tipo            text not null
                  check (tipo in ('postulacion', 'eleccion', 'recordatorio_24h', 'cancelacion')),
  asunto          text not null check (char_length(trim(asunto)) between 1 and 200),
  cuerpo          text not null check (char_length(trim(cuerpo)) between 1 and 2000),
  estado          text not null default 'pendiente'
                  check (estado in ('pendiente', 'enviado', 'cancelado', 'error')),
  programado_para timestamptz not null default now(),
  enviado_en      timestamptz,
  created_at      timestamptz not null default now()
);

create index if not exists cola_correos_pendientes_idx
  on public.cola_correos (programado_para)
  where estado = 'pendiente';

create index if not exists cola_correos_usuario_idx
  on public.cola_correos (usuario_id, created_at desc);

alter table public.cola_correos enable row level security;

revoke all on public.cola_correos from anon, authenticated;
grant select on public.cola_correos to authenticated;

create policy "cola_correos: leer los míos o admin" on public.cola_correos
  for select to authenticated
  using (usuario_id = (select auth.uid()) or public.es_admin());

-- Función interna auxiliar para encolar correos solo si el usuario tiene
-- `avisos_correo = true` y la cuenta está activa.
create or replace function public.encolar_correo_aviso(
  p_usuario_id      uuid,
  p_solicitud_id    uuid,
  p_tipo            text,
  p_asunto          text,
  p_cuerpo          text,
  p_programado_para timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_acepta boolean;
begin
  select p.avisos_correo and p.activo
    into v_acepta
    from public.perfiles p
   where p.id = p_usuario_id;

  if coalesce(v_acepta, false) then
    insert into public.cola_correos
      (usuario_id, solicitud_id, tipo, asunto, cuerpo, programado_para)
    values
      (p_usuario_id, p_solicitud_id, p_tipo, p_asunto, p_cuerpo, coalesce(p_programado_para, now()));
  end if;
end;
$$;

revoke execute on function public.encolar_correo_aviso(uuid, uuid, text, text, text, timestamptz)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Triggers de eventos (postulación, elección, recordatorio 24h, cancelación)
-- ---------------------------------------------------------------------------
create or replace function public.notificar_nueva_postulacion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cliente_id uuid;
  v_trabajadora_nombre text;
  v_zona text;
begin
  select s.cliente_id, z.nombre
    into v_cliente_id, v_zona
    from public.solicitudes s
    left join public.zonas z on z.id = s.zona_id
   where s.id = new.solicitud_id;

  select nombre into v_trabajadora_nombre
    from public.perfiles
   where id = new.trabajadora_id;

  if v_cliente_id is null then
    return new;
  end if;

  insert into public.avisos (usuario_id, tipo, titulo, mensaje, ruta)
  values (
    v_cliente_id,
    'postulacion',
    'Nueva postulación',
    coalesce(v_trabajadora_nombre, 'Una trabajadora') ||
      ' se postuló a tu solicitud' ||
      case when v_zona is not null then ' en ' || v_zona else '' end || '.',
    '/cliente/solicitudes/' || new.solicitud_id::text || '/postulantes'
  );

  perform public.encolar_correo_aviso(
    v_cliente_id,
    new.solicitud_id,
    'postulacion',
    'Nueva postulación en tu solicitud · LimpiaYa',
    coalesce(v_trabajadora_nombre, 'Una trabajadora') ||
      ' se ha postulado a tu solicitud de limpieza. Entra a LimpiaYa para revisar su perfil y elegir.'
  );

  return new;
end;
$$;

drop trigger if exists trg_notificar_nueva_postulacion on public.postulaciones;
create trigger trg_notificar_nueva_postulacion
  after insert on public.postulaciones
  for each row
  execute function public.notificar_nueva_postulacion();

create or replace function public.notificar_cambio_solicitud()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cliente_nombre text;
  v_trabajadora_nombre text;
  v_contraparte uuid;
  v_ruta_contraparte text;
  v_recordatorio timestamptz;
begin
  if new.estado = old.estado then
    return new;
  end if;

  select nombre into v_cliente_nombre from public.perfiles where id = new.cliente_id;
  if new.trabajadora_id is not null then
    select nombre into v_trabajadora_nombre from public.perfiles where id = new.trabajadora_id;
  end if;

  -- Elección de trabajadora (publicada -> asignada)
  if new.estado = 'asignada' and new.trabajadora_id is not null then
    insert into public.avisos (usuario_id, tipo, titulo, mensaje, ruta)
    values (
      new.trabajadora_id,
      'eleccion',
      '¡Fuiste elegida!',
      coalesce(v_cliente_nombre, 'El cliente') ||
        ' te eligió para el servicio. Ya puedes ver la dirección y escribir por el chat.',
      '/trabajadora/servicios/' || new.id::text
    );

    perform public.encolar_correo_aviso(
      new.trabajadora_id,
      new.id,
      'eleccion',
      '¡Te eligieron para un servicio! · LimpiaYa',
      coalesce(v_cliente_nombre, 'El cliente') ||
        ' confirmó tu postulación. Entra a LimpiaYa para ver el detalle del servicio.'
    );

    -- Recordatorio de 24 h antes del inicio (HU-49)
    v_recordatorio := new.inicio - interval '24 hours';
    if v_recordatorio > now() then
      perform public.encolar_correo_aviso(
        new.cliente_id,
        new.id,
        'recordatorio_24h',
        'Recordatorio: tu servicio es en 24 horas · LimpiaYa',
        'Tu servicio de limpieza con ' || coalesce(v_trabajadora_nombre, 'tu trabajadora') ||
          ' comienza en 24 horas.',
        v_recordatorio
      );
      perform public.encolar_correo_aviso(
        new.trabajadora_id,
        new.id,
        'recordatorio_24h',
        'Recordatorio: tienes un servicio en 24 horas · LimpiaYa',
        'Tu servicio con ' || coalesce(v_cliente_nombre, 'el cliente') ||
          ' comienza en 24 horas. Revisa la dirección en LimpiaYa.',
        v_recordatorio
      );
    end if;
  end if;

  -- Cancelación de servicio asignado o solicitud
  if new.estado = 'cancelada' then
    -- Cancelar recordatorios 24 h que aún no se enviaron
    update public.cola_correos
       set estado = 'cancelado'
     where solicitud_id = new.id
       and tipo = 'recordatorio_24h'
       and estado = 'pendiente';

    if new.trabajadora_id is not null then
      if new.cancelada_por = new.cliente_id then
        v_contraparte := new.trabajadora_id;
        v_ruta_contraparte := '/trabajadora/servicios/' || new.id::text;
      elsif new.cancelada_por = new.trabajadora_id then
        v_contraparte := new.cliente_id;
        v_ruta_contraparte := '/cliente/servicios/' || new.id::text;
      else
        -- Cancelado por administración (HU-34): avisar a ambas partes
        insert into public.avisos (usuario_id, tipo, titulo, mensaje, ruta)
        values
          (new.cliente_id, 'cancelacion', 'Servicio cancelado',
           coalesce(new.motivo_cancelacion, 'El servicio fue cancelado.'),
           '/cliente/servicios/' || new.id::text),
          (new.trabajadora_id, 'cancelacion', 'Servicio cancelado',
           coalesce(new.motivo_cancelacion, 'El servicio fue cancelado.'),
           '/trabajadora/servicios/' || new.id::text);

        perform public.encolar_correo_aviso(
          new.cliente_id, new.id, 'cancelacion',
          'Servicio cancelado · LimpiaYa',
          coalesce(new.motivo_cancelacion, 'Tu servicio ha sido cancelado.')
        );
        perform public.encolar_correo_aviso(
          new.trabajadora_id, new.id, 'cancelacion',
          'Servicio cancelado · LimpiaYa',
          coalesce(new.motivo_cancelacion, 'Tu servicio ha sido cancelado.')
        );
        return new;
      end if;

      insert into public.avisos (usuario_id, tipo, titulo, mensaje, ruta)
      values (
        v_contraparte,
        'cancelacion',
        'Servicio cancelado',
        'El servicio fue cancelado.' ||
          case when coalesce(trim(new.motivo_cancelacion), '') <> ''
               then ' Motivo: ' || trim(new.motivo_cancelacion)
               else '' end,
        v_ruta_contraparte
      );

      perform public.encolar_correo_aviso(
        v_contraparte,
        new.id,
        'cancelacion',
        'Servicio cancelado · LimpiaYa',
        'El servicio agendado fue cancelado.' ||
          case when coalesce(trim(new.motivo_cancelacion), '') <> ''
               then ' Motivo: ' || trim(new.motivo_cancelacion)
               else '' end
      );
    end if;
  end if;

  -- Servicio completado
  if new.estado = 'completada' and new.trabajadora_id is not null then
    insert into public.avisos (usuario_id, tipo, titulo, mensaje, ruta)
    values (
      new.trabajadora_id,
      'completada',
      'Servicio completado',
      coalesce(v_cliente_nombre, 'El cliente') ||
        ' marcó el servicio como completado. Ya puedes calificar tu experiencia.',
      '/trabajadora/servicios/' || new.id::text
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_notificar_cambio_solicitud on public.solicitudes;
create trigger trg_notificar_cambio_solicitud
  after update of estado on public.solicitudes
  for each row
  execute function public.notificar_cambio_solicitud();
