-- HU-42 · Desactivar mi cuenta
--
-- Criterios:
-- 1. Sin servicios asignados pendientes, al confirmar, el perfil deja de
--    verse y se cierra la sesión (la app cierra la sesión; la base oculta).
-- 2. Con servicios asignados pendientes, no se desactiva y se explica por qué.
-- 3. Una reseña de una cuenta desactivada se muestra como "Usuario inactivo".
--
-- La columna NO se puede escribir desde la app: el grant de `perfiles` sigue
-- siendo (nombre, telefono, foto_path). Solo la función `desactivar_cuenta()`.

alter table public.perfiles
  add column activo boolean not null default true;

comment on column public.perfiles.activo is
  'HU-42: false cuando la persona desactiva su cuenta. Solo lo cambia desactivar_cuenta().';

-- ---------------------------------------------------------------------------
-- 1. mi_sesion() avisa si la cuenta está activa. La app la usa para no dejar
--    entrar a una cuenta desactivada.
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
    'verificacion', coalesce(
      (select t.verificacion from public.trabajadoras t where t.id = p.id),
      (select c.verificacion from public.clientes c where c.id = p.id)
    ),
    'activo', p.activo
  )
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- 2. desactivar_cuenta()
--
--    - Bloquea si hay servicios asignados sin completar (criterio 2).
--    - Cancela las solicitudes publicadas del cliente: si no, seguirían
--      visibles con su dirección aunque el perfil ya no se vea.
--    - Retira las postulaciones pendientes de la trabajadora.
--    - Marca el perfil como inactivo.
-- ---------------------------------------------------------------------------
create or replace function public.desactivar_cuenta()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := (select auth.uid());
begin
  if v_id is null then
    raise exception 'Inicia sesión para desactivar tu cuenta';
  end if;

  if exists (
    select 1
      from public.solicitudes s
     where (s.cliente_id = v_id or s.trabajadora_id = v_id)
       and s.estado = 'asignada'
  ) then
    raise exception 'Primero completa o cancela tus servicios asignados';
  end if;

  -- Cliente: lo publicado deja de existir para las trabajadoras.
  update public.solicitudes
     set estado             = 'cancelada',
         cancelada_en       = now(),
         cancelada_por      = v_id,
         motivo_cancelacion = 'Cuenta desactivada'
   where cliente_id = v_id
     and estado = 'publicada';

  update public.postulaciones
     set estado = 'solicitud_cancelada'
   where estado = 'pendiente'
     and solicitud_id in (
       select id from public.solicitudes
        where cliente_id = v_id and estado = 'cancelada');

  -- Trabajadora: sus postulaciones pendientes se retiran.
  update public.postulaciones
     set estado = 'retirada'
   where trabajadora_id = v_id
     and estado = 'pendiente';

  update public.perfiles
     set activo = false
   where id = v_id;
end;
$$;

revoke execute on function public.desactivar_cuenta() from public, anon;
grant execute on function public.desactivar_cuenta() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. La trabajadora inactiva desaparece del directorio y del perfil público.
--    (Mismas columnas y en el mismo orden que la versión de HU-25.)
-- ---------------------------------------------------------------------------
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
 where p.activo;

-- ---------------------------------------------------------------------------
-- 4. Las reseñas de una cuenta desactivada llevan "Usuario inactivo"
--    (criterio 3). El resto de la vista no cambia.
-- ---------------------------------------------------------------------------
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
 where c.created_at <= now() - interval '7 days'
    or exists (
      select 1 from public.calificaciones otra
       where otra.solicitud_id = c.solicitud_id
         and otra.autor_id = c.destinatario_id
    );

-- ---------------------------------------------------------------------------
-- 5. Datos públicos: la app puede saber si una cuenta está activa (para
--    mostrarla o no). Se agrega al final: "create or replace view" solo
--    permite añadir columnas al final.
-- ---------------------------------------------------------------------------
create or replace view public.perfiles_publicos as
select p.id,
       p.rol,
       p.nombre,
       p.foto_path,
       coalesce(coalesce(t.verificacion, c.verificacion) = 'aprobada', false)
         as verificada,
       p.activo
  from public.perfiles p
  left join public.trabajadoras t on t.id = p.id
  left join public.clientes c on c.id = p.id;
