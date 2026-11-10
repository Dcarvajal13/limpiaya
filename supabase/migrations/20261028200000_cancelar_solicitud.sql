-- ---------------------------------------------------------------------------
-- HU-10 · Cancelar una solicitud sin asignar
--
-- El cliente no puede escribir la columna estado (grant de HD-04), así que
-- la cancelación pasa por esta función:
-- - c1: solo una solicitud Publicada del propio cliente pasa a Cancelada.
--   Deja de salir en solicitudes_publicas para las trabajadoras, porque esa
--   vista solo lista las Publicadas.
-- - c3: sus postulaciones pendientes pasan a "solicitud_cancelada".
-- ---------------------------------------------------------------------------
create or replace function public.cancelar_solicitud(
  p_solicitud uuid,
  p_motivo    text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.solicitudes
     set estado             = 'cancelada',
         cancelada_en       = now(),
         cancelada_por      = (select auth.uid()),
         motivo_cancelacion = nullif(left(trim(coalesce(p_motivo, '')), 300), '')
   where id = p_solicitud
     and cliente_id = (select auth.uid())
     and estado = 'publicada';

  if not found then
    raise exception 'Solo puedes cancelar una solicitud publicada';
  end if;

  update public.postulaciones
     set estado = 'solicitud_cancelada'
   where solicitud_id = p_solicitud
     and estado = 'pendiente';
end;
$$;

revoke execute on function public.cancelar_solicitud(uuid, text) from public, anon;
grant execute on function public.cancelar_solicitud(uuid, text) to authenticated;

-- El cliente ve el motivo en su tarjeta "Cancelada" (Figma C05). La columna
-- se agrega al final porque "create or replace view" solo permite eso.
create or replace view public.solicitudes_publicas as
select s.id,
       s.cliente_id,
       s.trabajadora_id,
       s.estado,
       s.tipo,
       s.zona_id,
       z.nombre as zona,
       s.inicio,
       s.horas_estimadas,
       s.fin,
       s.pago_ofrecido,
       s.metodo_pago,
       s.habitaciones,
       s.banos,
       s.tiene_mascotas,
       s.productos_por,
       s.notas,
       s.created_at,
       (select count(*)
          from public.postulaciones po
         where po.solicitud_id = s.id
           and po.estado in ('pendiente', 'aceptada')) as num_postulantes,
       exists (
         select 1 from public.postulaciones po
          where po.solicitud_id = s.id
            and po.trabajadora_id = (select auth.uid())
            and po.estado in ('pendiente', 'aceptada')) as ya_me_postule,
       s.motivo_cancelacion
  from public.solicitudes s
  join public.zonas z on z.id = s.zona_id
 where (
         s.estado = 'publicada'
         and s.inicio > now()
         and exists (
           select 1 from public.trabajadora_zonas tz
            where tz.trabajadora_id = (select auth.uid())
              and tz.zona_id = s.zona_id)
       )
    or s.cliente_id = (select auth.uid())
    or s.trabajadora_id = (select auth.uid())
    or exists (
         select 1 from public.postulaciones po
          where po.solicitud_id = s.id
            and po.trabajadora_id = (select auth.uid()))
    or (select public.es_admin());
