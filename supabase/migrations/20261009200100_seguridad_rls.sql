-- =============================================================================
-- LimpiaYa · Migración 2: seguridad (HD-02 criterio 3, HD-03 criterio 2, HD-06)
-- - Funciones de ayuda para las políticas
-- - Perfil automático al registrarse (HU-01)
-- - mi_sesion(): rol y estado del perfil para el login (HU-02A / HU-02B)
-- - Permisos por columna y políticas RLS de todas las tablas
-- Regla general: sin sesión no se lee nada; cada quien ve solo lo suyo.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Funciones de ayuda (se usan dentro de las políticas)
-- ---------------------------------------------------------------------------
create or replace function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.perfiles
     where id = (select auth.uid()) and rol = 'admin'
  );
$$;

-- ¿El usuario actual es el cliente o la trabajadora asignada de esa solicitud?
create or replace function public.es_participante(p_solicitud uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.solicitudes s
     where s.id = p_solicitud
       and s.trabajadora_id is not null
       and (select auth.uid()) in (s.cliente_id, s.trabajadora_id)
  );
$$;

-- HU-38: se puede escribir si el servicio está Asignado, o hasta 7 días
-- después de Completado / Cancelado.
create or replace function public.chat_abierto(p_solicitud uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.solicitudes s
     where s.id = p_solicitud
       and s.trabajadora_id is not null
       and (select auth.uid()) in (s.cliente_id, s.trabajadora_id)
       and (
         s.estado = 'asignada'
         or (s.estado in ('completada', 'cancelada')
             and coalesce(s.completada_en, s.cancelada_en) > now() - interval '7 days')
       )
  );
$$;

-- HU-12 (criterios 1 y 4) y HU-45 (criterio 3): trabajadora verificada,
-- solicitud Publicada, futura y en una de sus zonas.
-- El cruce de horarios (HU-12 criterio 3) se decide en HD-04.
create or replace function public.puede_postularse(p_solicitud uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.solicitudes s
      join public.trabajadoras t on t.id = (select auth.uid())
      join public.trabajadora_zonas tz on tz.trabajadora_id = t.id and tz.zona_id = s.zona_id
     where s.id = p_solicitud
       and s.estado = 'publicada'
       and s.inicio > now()
       and t.verificacion = 'aprobada'
  );
$$;

-- HU-29 / HU-30: solo se califica a la otra parte de un servicio Completado.
create or replace function public.puede_calificar(p_solicitud uuid, p_destinatario uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.solicitudes s
     where s.id = p_solicitud
       and s.estado = 'completada'
       and (
         (s.cliente_id = (select auth.uid()) and s.trabajadora_id = p_destinatario)
         or (s.trabajadora_id = (select auth.uid()) and s.cliente_id = p_destinatario)
       )
  );
$$;

-- ---------------------------------------------------------------------------
-- Perfil automático al registrarse (HU-01). La app manda en signUp:
--   data: { nombre, telefono, rol: 'cliente' | 'trabajadora' }
-- Nadie puede registrarse como admin (HD-06, criterio 2).
-- ---------------------------------------------------------------------------
create or replace function public.crear_perfil_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_rol  text  := coalesce(nullif(v_meta ->> 'rol', ''), 'cliente');
begin
  if v_rol not in ('cliente', 'trabajadora') then
    raise exception 'Rol no permitido en el registro: %', v_rol using errcode = '22023';
  end if;

  insert into public.perfiles (id, rol, nombre, telefono)
  values (
    new.id,
    v_rol::public.rol_usuario,
    coalesce(nullif(trim(v_meta ->> 'nombre'), ''), split_part(new.email, '@', 1)),
    nullif(trim(v_meta ->> 'telefono'), '')
  );

  if v_rol = 'cliente' then
    insert into public.clientes (id) values (new.id);
  else
    insert into public.trabajadoras (id) values (new.id);
  end if;

  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil_nuevo_usuario();

-- ---------------------------------------------------------------------------
-- mi_sesion(): lo que la app necesita al iniciar sesión (HU-02A, HU-02B)
-- Uso en Flutter: await supabase.rpc('mi_sesion')
-- ---------------------------------------------------------------------------
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
    'verificacion', (select t.verificacion from public.trabajadoras t where t.id = p.id)
  )
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- Permisos: se quita todo y se da solo lo necesario, columna por columna.
-- Así, por ejemplo, nadie puede cambiarse el rol ni marcarse verificada.
-- ---------------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

grant usage on schema public to authenticated;

grant execute on function
  public.es_admin(),
  public.es_participante(uuid),
  public.chat_abierto(uuid),
  public.puede_postularse(uuid),
  public.puede_calificar(uuid, uuid),
  public.mi_sesion()
to authenticated;

grant select on public.zonas to authenticated;

grant select on public.perfiles to authenticated;
grant update (nombre, telefono, foto_path) on public.perfiles to authenticated;

grant select on public.clientes to authenticated;
grant insert (id, zona_id, direccion, punto_referencia) on public.clientes to authenticated;
grant update (zona_id, direccion, punto_referencia) on public.clientes to authenticated;

grant select on public.trabajadoras to authenticated;
grant insert (id, experiencia_anios, tarifa_referencia, descripcion) on public.trabajadoras to authenticated;
grant update (experiencia_anios, tarifa_referencia, descripcion) on public.trabajadoras to authenticated;

grant select, insert, delete on public.trabajadora_zonas to authenticated;
grant select, insert, delete on public.trabajadora_servicios to authenticated;

grant select on public.solicitudes to authenticated;
grant insert (cliente_id, tipo, zona_id, direccion, punto_referencia, inicio, horas_estimadas,
              pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por, notas)
  on public.solicitudes to authenticated;
grant update (tipo, zona_id, direccion, punto_referencia, inicio, horas_estimadas,
              pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por, notas)
  on public.solicitudes to authenticated;

grant select on public.postulaciones to authenticated;
grant insert (solicitud_id, trabajadora_id, mensaje) on public.postulaciones to authenticated;
grant update (estado) on public.postulaciones to authenticated;

grant select on public.calificaciones to authenticated;
grant insert (solicitud_id, autor_id, destinatario_id, estrellas, comentario, motivo)
  on public.calificaciones to authenticated;

grant select on public.verificaciones to authenticated;
grant insert (trabajadora_id, cedula_path, selfie_path) on public.verificaciones to authenticated;
grant update (estado, motivo_rechazo, revisada_por, revisada_en) on public.verificaciones to authenticated;

grant select on public.mensajes to authenticated;
grant insert (solicitud_id, autor_id, contenido) on public.mensajes to authenticated;

-- ---------------------------------------------------------------------------
-- RLS: activar en todas las tablas
-- ---------------------------------------------------------------------------
alter table public.zonas                 enable row level security;
alter table public.perfiles              enable row level security;
alter table public.clientes              enable row level security;
alter table public.trabajadoras          enable row level security;
alter table public.trabajadora_zonas     enable row level security;
alter table public.trabajadora_servicios enable row level security;
alter table public.solicitudes           enable row level security;
alter table public.postulaciones         enable row level security;
alter table public.calificaciones        enable row level security;
alter table public.verificaciones        enable row level security;
alter table public.mensajes              enable row level security;

-- Zonas: cualquiera con sesión
create policy "zonas: leer con sesión" on public.zonas
  for select to authenticated using (true);

-- Perfiles: cada quien el suyo (los demás se ven por la vista perfiles_publicos)
create policy "perfiles: leer el propio" on public.perfiles
  for select to authenticated
  using (id = (select auth.uid()) or (select public.es_admin()));

create policy "perfiles: editar el propio" on public.perfiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Clientes
create policy "clientes: leer el propio" on public.clientes
  for select to authenticated
  using (id = (select auth.uid()) or (select public.es_admin()));

create policy "clientes: crear el propio" on public.clientes
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy "clientes: editar el propio" on public.clientes
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Trabajadoras
create policy "trabajadoras: leer el propio" on public.trabajadoras
  for select to authenticated
  using (id = (select auth.uid()) or (select public.es_admin()));

create policy "trabajadoras: crear el propio" on public.trabajadoras
  for insert to authenticated
  with check (id = (select auth.uid()));

create policy "trabajadoras: editar el propio" on public.trabajadoras
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Zonas y servicios de la trabajadora
create policy "trabajadora_zonas: leer las propias" on public.trabajadora_zonas
  for select to authenticated
  using (trabajadora_id = (select auth.uid()) or (select public.es_admin()));

create policy "trabajadora_zonas: agregar las propias" on public.trabajadora_zonas
  for insert to authenticated
  with check (trabajadora_id = (select auth.uid()));

create policy "trabajadora_zonas: quitar las propias" on public.trabajadora_zonas
  for delete to authenticated
  using (trabajadora_id = (select auth.uid()));

create policy "trabajadora_servicios: leer los propios" on public.trabajadora_servicios
  for select to authenticated
  using (trabajadora_id = (select auth.uid()) or (select public.es_admin()));

create policy "trabajadora_servicios: agregar los propios" on public.trabajadora_servicios
  for insert to authenticated
  with check (trabajadora_id = (select auth.uid()));

create policy "trabajadora_servicios: quitar los propios" on public.trabajadora_servicios
  for delete to authenticated
  using (trabajadora_id = (select auth.uid()));

-- Solicitudes. La tabla tiene la dirección exacta: solo la ven el cliente
-- dueño y la trabajadora asignada. Las trabajadoras buscan en la vista
-- solicitudes_publicas, que no trae la dirección (HU-05 c3, HU-45 c2).
create policy "solicitudes: leer las propias o asignadas" on public.solicitudes
  for select to authenticated
  using (
    cliente_id = (select auth.uid())
    or trabajadora_id = (select auth.uid())
    or (select public.es_admin())
  );

create policy "solicitudes: el cliente publica" on public.solicitudes
  for insert to authenticated
  with check (cliente_id = (select auth.uid()));

-- HU-09: solo se edita mientras está Publicada.
-- Cambiar de estado (asignar, completar, cancelar) se define en HD-04.
create policy "solicitudes: el cliente edita mientras está publicada" on public.solicitudes
  for update to authenticated
  using (cliente_id = (select auth.uid()) and estado = 'publicada')
  with check (cliente_id = (select auth.uid()) and estado = 'publicada');

-- Postulaciones
create policy "postulaciones: leer las propias o las de mis solicitudes" on public.postulaciones
  for select to authenticated
  using (
    trabajadora_id = (select auth.uid())
    or exists (
      select 1 from public.solicitudes s
       where s.id = solicitud_id and s.cliente_id = (select auth.uid()))
    or (select public.es_admin())
  );

create policy "postulaciones: la trabajadora se postula" on public.postulaciones
  for insert to authenticated
  with check (
    trabajadora_id = (select auth.uid())
    and public.puede_postularse(solicitud_id)
  );

-- HU-26: retirar una postulación pendiente.
create policy "postulaciones: la trabajadora retira la suya" on public.postulaciones
  for update to authenticated
  using (trabajadora_id = (select auth.uid()) and estado = 'pendiente')
  with check (trabajadora_id = (select auth.uid()) and estado = 'retirada');

-- Calificaciones (las reseñas públicas se leen en la vista resenas_publicas)
create policy "calificaciones: leer las que escribí" on public.calificaciones
  for select to authenticated
  using (autor_id = (select auth.uid()) or (select public.es_admin()));

create policy "calificaciones: calificar a la otra parte" on public.calificaciones
  for insert to authenticated
  with check (
    autor_id = (select auth.uid())
    and public.puede_calificar(solicitud_id, destinatario_id)
  );

-- Verificaciones de identidad (HU-21, HU-33)
create policy "verificaciones: leer las propias" on public.verificaciones
  for select to authenticated
  using (trabajadora_id = (select auth.uid()) or (select public.es_admin()));

create policy "verificaciones: la trabajadora envía la suya" on public.verificaciones
  for insert to authenticated
  with check (trabajadora_id = (select auth.uid()) and estado = 'en_revision');

create policy "verificaciones: el admin aprueba o rechaza" on public.verificaciones
  for update to authenticated
  using ((select public.es_admin()))
  with check ((select public.es_admin()));

-- Mensajes del chat (HU-38)
create policy "mensajes: leer los de mis servicios" on public.mensajes
  for select to authenticated
  using (public.es_participante(solicitud_id) or (select public.es_admin()));

create policy "mensajes: escribir si el chat está abierto" on public.mensajes
  for insert to authenticated
  with check (autor_id = (select auth.uid()) and public.chat_abierto(solicitud_id));

-- Chat en tiempo real: los mensajes nuevos llegan sin recargar (HU-38 c2)
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.mensajes;
  end if;
end;
$$;
