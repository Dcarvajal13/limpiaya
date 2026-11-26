-- =============================================================================
-- HU-34 · Suspender o reactivar cuentas (admin) con motivo y efecto en servicios
-- HU-35 · Moderar reseñas reportadas (cola de moderación + ocultar reseña)
-- HU-36 · Métricas de la plataforma (totales del mes, % postulación, % completado)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. HU-34 · Columnas de suspensión en perfiles
-- ---------------------------------------------------------------------------
alter table public.perfiles
  add column if not exists suspendido boolean not null default false,
  add column if not exists motivo_suspension text,
  add column if not exists suspendido_en timestamptz;

comment on column public.perfiles.suspendido is
  'HU-34: true cuando un admin suspende la cuenta. Solo cambia por suspender_cuenta/reactivar_cuenta.';

-- Actualiza mi_sesion() para exponer suspendido, motivo_suspension y avisos_correo
create or replace function public.mi_sesion()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id,
    'rol', p.rol,
    'nombre', p.nombre,
    'foto_path', p.foto_path,
    'perfil_completo', case p.rol
      when 'cliente' then exists (
        select 1 from public.clientes c
         where c.id = p.id and c.zona_id is not null and c.direccion is not null)
      when 'trabajadora' then
        exists (select 1 from public.trabajadora_zonas z where z.trabajadora_id = p.id)
        and exists (select 1 from public.trabajadora_servicios sv where sv.trabajadora_id = p.id)
      else true
    end,
    'verificacion', coalesce(
      (select t.verificacion from public.trabajadoras t where t.id = p.id),
      (select c.verificacion from public.clientes c where c.id = p.id)
    ),
    'activo', p.activo,
    'suspendido', p.suspendido,
    'motivo_suspension', p.motivo_suspension,
    'avisos_correo', p.avisos_correo
  )
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

-- Trabajadoras suspendidas tampoco aparecen en el directorio público
create or replace view public.trabajadoras_publicas as
select p.id,
       p.nombre,
       p.foto_path,
       t.experiencia_anios,
       t.tarifa_referencia,
       t.descripcion,
       t.verificacion = 'aprobada' as verificada,
       coalesce((select array_agg(z.nombre order by z.nombre)
                   from public.trabajadora_zonas tz
                   join public.zonas z on z.id = tz.zona_id
                  where tz.trabajadora_id = p.id), '{}') as zonas,
       coalesce((select array_agg(sv.tipo order by sv.tipo)
                   from public.trabajadora_servicios sv
                  where sv.trabajadora_id = p.id), '{}') as servicios,
       r.promedio,
       r.total_resenas,
       r.servicios_completados,
       n.destacada,
       coalesce((select array_agg(tz.zona_id order by tz.zona_id)
                   from public.trabajadora_zonas tz
                  where tz.trabajadora_id = p.id), '{}') as zona_ids
  from public.perfiles p
  join public.trabajadoras t on t.id = p.id
  join public.reputacion r on r.usuario_id = p.id
  join public.nivel_trabajadoras n on n.trabajadora_id = p.id
 where p.activo and not p.suspendido;

-- perfiles_publicos agrega p.suspendido al final (compatible con create or replace)
create or replace view public.perfiles_publicos as
select p.id,
       p.rol,
       p.nombre,
       p.foto_path,
       coalesce(coalesce(t.verificacion, c.verificacion) = 'aprobada', false)
         as verificada,
       p.activo,
       p.suspendido
  from public.perfiles p
  left join public.trabajadoras t on t.id = p.id
  left join public.clientes c on c.id = p.id;

-- Listar cuentas para administración (solo admin)
create or replace function public.listar_cuentas_admin()
returns table (
  id                uuid,
  nombre            text,
  rol               public.rol_usuario,
  foto_path         text,
  activo            boolean,
  suspendido        boolean,
  motivo_suspension text,
  suspendido_en     timestamptz,
  verificacion      public.estado_verificacion,
  servicios_activos bigint,
  creado_en         timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede ver las cuentas';
  end if;

  return query
  select p.id,
         p.nombre,
         p.rol,
         p.foto_path,
         p.activo,
         p.suspendido,
         p.motivo_suspension,
         p.suspendido_en,
         coalesce(t.verificacion, c.verificacion) as verificacion,
         (select count(*)
            from public.solicitudes s
           where (s.cliente_id = p.id or s.trabajadora_id = p.id)
             and s.estado in ('publicada', 'asignada')) as servicios_activos,
         p.created_at as creado_en
    from public.perfiles p
    left join public.trabajadoras t on t.id = p.id
    left join public.clientes c on c.id = p.id
   where p.rol <> 'admin'
   order by p.suspendido desc, p.created_at desc;
end;
$$;

revoke execute on function public.listar_cuentas_admin() from public, anon;
grant execute on function public.listar_cuentas_admin() to authenticated;

-- Suspender cuenta con motivo obligatorio + efecto en solicitudes y servicios
create or replace function public.suspender_cuenta(p_usuario uuid, p_motivo text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rol public.rol_usuario;
  v_motivo text := trim(coalesce(p_motivo, ''));
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede suspender cuentas';
  end if;

  if v_motivo = '' then
    raise exception 'Indica el motivo de la suspensión';
  end if;

  select rol into v_rol from public.perfiles where id = p_usuario;
  if v_rol is null then
    raise exception 'No encontramos esa cuenta';
  end if;
  if v_rol = 'admin' then
    raise exception 'No se puede suspender una cuenta de administrador';
  end if;

  -- 1. Cancelar solicitudes publicadas del cliente
  update public.solicitudes
     set estado             = 'cancelada',
         cancelada_en       = now(),
         cancelada_por      = null,
         motivo_cancelacion = 'Cuenta suspendida por administración'
   where cliente_id = p_usuario
     and estado = 'publicada';

  -- 2. Cancelar servicios asignados en los que participe (cliente o trabajadora)
  --    El trigger `notificar_cambio_solicitud` avisa automáticamente a la contraparte.
  update public.solicitudes
     set estado             = 'cancelada',
         cancelada_en       = now(),
         cancelada_por      = null,
         motivo_cancelacion = 'Servicio cancelado porque una de las cuentas fue suspendida'
   where (cliente_id = p_usuario or trabajadora_id = p_usuario)
     and estado = 'asignada';

  -- 3. Actualizar postulaciones asociadas a solicitudes canceladas
  update public.postulaciones
     set estado = 'solicitud_cancelada'
   where estado in ('pendiente', 'aceptada')
     and solicitud_id in (
       select id from public.solicitudes
        where (cliente_id = p_usuario or trabajadora_id = p_usuario)
          and estado = 'cancelada'
     );

  -- 4. Retirar postulaciones pendientes si es trabajadora
  update public.postulaciones
     set estado = 'retirada'
   where trabajadora_id = p_usuario
     and estado = 'pendiente';

  -- 5. Marcar la cuenta como suspendida
  update public.perfiles
     set suspendido        = true,
         motivo_suspension = v_motivo,
         suspendido_en     = now()
   where id = p_usuario;
end;
$$;

revoke execute on function public.suspender_cuenta(uuid, text) from public, anon;
grant execute on function public.suspender_cuenta(uuid, text) to authenticated;

-- Reactivar cuenta suspendida
create or replace function public.reactivar_cuenta(p_usuario uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede reactivar cuentas';
  end if;

  update public.perfiles
     set suspendido        = false,
         motivo_suspension = null,
         suspendido_en     = null
   where id = p_usuario;

  if not found then
    raise exception 'No encontramos esa cuenta';
  end if;

  insert into public.avisos (usuario_id, tipo, titulo, mensaje)
  values (
    p_usuario,
    'cuenta',
    'Cuenta reactivada',
    'Tu cuenta en LimpiaYa ha sido reactivada por el equipo de administración.'
  );
end;
$$;

revoke execute on function public.reactivar_cuenta(uuid) from public, anon;
grant execute on function public.reactivar_cuenta(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 2. HU-35 · Moderar reseñas reportadas
-- ---------------------------------------------------------------------------
alter table public.calificaciones
  add column if not exists oculta boolean not null default false;

comment on column public.calificaciones.oculta is
  'HU-35: true cuando un admin oculta una reseña reportada. Deja de verse y de contar en el promedio.';

-- resenas_publicas excluye las reseñas ocultadas por moderación
create or replace view public.resenas_publicas as
select c.id,
       c.solicitud_id,
       c.autor_id,
       case when a.activo then a.nombre else 'Usuario inactivo' end
         as autor_nombre,
       c.destinatario_id,
       c.estrellas,
       c.comentario,
       c.created_at,
       rr.texto as respuesta,
       rr.updated_at as respuesta_en
  from public.calificaciones c
  join public.perfiles a on a.id = c.autor_id
  left join public.respuestas_resenas rr on rr.calificacion_id = c.id
 where not c.oculta
   and (
     c.created_at <= now() - interval '7 days'
     or exists (
       select 1 from public.calificaciones otra
        where otra.solicitud_id = c.solicitud_id
          and otra.autor_id = c.destinatario_id
     )
   );

create table if not exists public.reportes_resenas (
  id              uuid primary key default gen_random_uuid(),
  calificacion_id uuid not null references public.calificaciones(id) on delete cascade,
  reportado_por   uuid not null references public.perfiles(id) on delete cascade,
  motivo          text not null check (char_length(trim(motivo)) between 1 and 400),
  estado          text not null default 'pendiente'
                  check (estado in ('pendiente', 'mantenida', 'oculta')),
  nota_admin      text,
  resuelto_por    uuid references public.perfiles(id),
  resuelto_en     timestamptz,
  created_at      timestamptz not null default now(),
  unique (calificacion_id, reportado_por)
);

create index if not exists reportes_resenas_estado_idx
  on public.reportes_resenas (estado, created_at asc);

alter table public.reportes_resenas enable row level security;

revoke all on public.reportes_resenas from anon, authenticated;
grant select on public.reportes_resenas to authenticated;

create policy "reportes_resenas: leer admin o autor del reporte" on public.reportes_resenas
  for select to authenticated
  using (public.es_admin() or reportado_por = (select auth.uid()));

-- Reportar una reseña (para alimentar la cola de moderación)
create or replace function public.reportar_resena(p_calificacion uuid, p_motivo text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_motivo text := trim(coalesce(p_motivo, ''));
begin
  if v_uid is null then
    raise exception 'Inicia sesión para reportar una reseña';
  end if;
  if v_motivo = '' then
    raise exception 'Indica el motivo del reporte';
  end if;
  if not exists (select 1 from public.calificaciones where id = p_calificacion) then
    raise exception 'No encontramos esa reseña';
  end if;

  insert into public.reportes_resenas (calificacion_id, reportado_por, motivo)
  values (p_calificacion, v_uid, v_motivo)
  on conflict (calificacion_id, reportado_por) do nothing;
end;
$$;

revoke execute on function public.reportar_resena(uuid, text) from public, anon;
grant execute on function public.reportar_resena(uuid, text) to authenticated;

-- Cola de moderación (solo admin)
create or replace function public.listar_resenas_reportadas()
returns table (
  reporte_id           uuid,
  calificacion_id      uuid,
  estrellas            smallint,
  comentario           text,
  autor_nombre         text,
  destinatario_nombre  text,
  reportado_por_nombre text,
  motivo_reporte       text,
  estado               text,
  nota_admin           text,
  creado_en            timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede moderar reseñas';
  end if;

  return query
  select r.id as reporte_id,
         r.calificacion_id,
         c.estrellas,
         c.comentario,
         autor.nombre as autor_nombre,
         dest.nombre as destinatario_nombre,
         rep.nombre as reportado_por_nombre,
         r.motivo as motivo_reporte,
         r.estado,
         r.nota_admin,
         r.created_at as creado_en
    from public.reportes_resenas r
    join public.calificaciones c on c.id = r.calificacion_id
    join public.perfiles autor on autor.id = c.autor_id
    join public.perfiles dest on dest.id = c.destinatario_id
    join public.perfiles rep on rep.id = r.reportado_por
   where r.estado = 'pendiente'
   order by r.created_at asc;
end;
$$;

revoke execute on function public.listar_resenas_reportadas() from public, anon;
grant execute on function public.listar_resenas_reportadas() to authenticated;

-- Moderar una reseña reportada: 'ocultar' o 'mantener'
create or replace function public.moderar_resena(
  p_reporte uuid,
  p_accion  text,
  p_nota    text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := (select auth.uid());
  v_calificacion_id uuid;
  v_estado_final text;
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede moderar reseñas';
  end if;

  if p_accion not in ('ocultar', 'mantener') then
    raise exception 'Acción inválida. Usa ocultar o mantener.';
  end if;

  select calificacion_id
    into v_calificacion_id
    from public.reportes_resenas
   where id = p_reporte;

  if v_calificacion_id is null then
    raise exception 'No encontramos ese reporte';
  end if;

  if p_accion = 'ocultar' then
    update public.calificaciones
       set oculta = true
     where id = v_calificacion_id;
    v_estado_final := 'oculta';
  else
    v_estado_final := 'mantenida';
  end if;

  update public.reportes_resenas
     set estado       = v_estado_final,
         nota_admin   = nullif(trim(coalesce(p_nota, '')), ''),
         resuelto_por = v_admin,
         resuelto_en  = now()
   where calificacion_id = v_calificacion_id
     and estado = 'pendiente';
end;
$$;

revoke execute on function public.moderar_resena(uuid, text, text) from public, anon;
grant execute on function public.moderar_resena(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. HU-36 · Métricas de la plataforma (totales del mes, % postulación, % completado)
-- ---------------------------------------------------------------------------
create or replace function public.metricas_plataforma(p_mes date default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_inicio timestamptz;
  v_fin    timestamptz;
  v_total_solicitudes int;
  v_con_postulacion   int;
  v_asignadas         int;
  v_completadas       int;
  v_canceladas        int;
  v_clientes_nuevos   int;
  v_trab_nuevas       int;
  v_trab_verificadas  int;
  v_volumen_usd       numeric;
begin
  if not public.es_admin() then
    raise exception 'Solo el administrador puede ver las métricas';
  end if;

  v_inicio := date_trunc('month', coalesce(p_mes::timestamptz, now()));
  v_fin    := v_inicio + interval '1 month';

  select count(*),
         count(*) filter (where exists (
           select 1 from public.postulaciones po where po.solicitud_id = s.id
         )),
         count(*) filter (where s.estado = 'asignada'),
         count(*) filter (where s.estado = 'completada'),
         count(*) filter (where s.estado = 'cancelada'),
         coalesce(sum(s.pago_ofrecido) filter (where s.estado = 'completada'), 0)
    into v_total_solicitudes,
         v_con_postulacion,
         v_asignadas,
         v_completadas,
         v_canceladas,
         v_volumen_usd
    from public.solicitudes s
   where s.created_at >= v_inicio
     and s.created_at < v_fin;

  select count(*) filter (where rol = 'cliente'),
         count(*) filter (where rol = 'trabajadora')
    into v_clientes_nuevos, v_trab_nuevas
    from public.perfiles
   where created_at >= v_inicio
     and created_at < v_fin;

  select count(*)
    into v_trab_verificadas
    from public.trabajadoras t
    join public.perfiles p on p.id = t.id
   where t.verificacion = 'aprobada'
     and p.activo
     and not p.suspendido;

  return jsonb_build_object(
    'mes', to_char(v_inicio, 'YYYY-MM-DD'),
    'total_solicitudes', v_total_solicitudes,
    'solicitudes_con_postulacion', v_con_postulacion,
    'pct_con_postulacion', case
      when v_total_solicitudes > 0
      then round((v_con_postulacion::numeric * 100.0) / v_total_solicitudes, 1)
      else 0
    end,
    'solicitudes_asignadas', v_asignadas,
    'solicitudes_completadas', v_completadas,
    'solicitudes_canceladas', v_canceladas,
    'pct_completado', case
      when v_total_solicitudes > 0
      then round((v_completadas::numeric * 100.0) / v_total_solicitudes, 1)
      else 0
    end,
    'clientes_nuevos', v_clientes_nuevos,
    'trabajadoras_nuevas', v_trab_nuevas,
    'trabajadoras_verificadas', v_trab_verificadas,
    'volumen_usd', v_volumen_usd
  );
end;
$$;

revoke execute on function public.metricas_plataforma(date) from public, anon;
grant execute on function public.metricas_plataforma(date) to authenticated;
