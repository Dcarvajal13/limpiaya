-- ---------------------------------------------------------------------------
-- HU-15 · Elegir a una trabajadora
--
-- El cliente no puede escribir las columnas estado ni trabajadora_id
-- (grant de HD-04), así que la elección pasa por esta función, igual que
-- cancelar_solicitud (HU-10):
-- - c1: la solicitud Publicada del propio cliente pasa a Asignada con esa
--   trabajadora, y su postulación a Aceptada.
-- - c2: las demás postulaciones pendientes pasan a No seleccionada.
-- - c3: desde ese momento la trabajadora puede leer la fila completa de
--   solicitudes, con la dirección exacta y el punto de referencia (política
--   "solicitudes: leer las propias o asignadas").
-- - c4: si la solicitud ya está Asignada, la función falla y no cambia nada.
--
-- La fila de la solicitud se bloquea (for update) para que dos clics seguidos
-- o dos pestañas abiertas no asignen a dos trabajadoras.
-- ---------------------------------------------------------------------------
create or replace function public.elegir_trabajadora(p_postulacion uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_solicitud   public.solicitudes%rowtype;
  v_trabajadora uuid;
begin
  select s.*
    into v_solicitud
    from public.postulaciones po
    join public.solicitudes s on s.id = po.solicitud_id
   where po.id = p_postulacion
     and s.cliente_id = (select auth.uid())
     for update of s;

  if not found then
    raise exception 'Esta postulación ya no está disponible';
  end if;

  if v_solicitud.estado = 'cancelada' then
    raise exception 'Esta solicitud fue cancelada';
  elsif v_solicitud.estado <> 'publicada' then
    raise exception 'Esta solicitud ya tiene una trabajadora asignada';
  end if;

  -- Se lee después del bloqueo: pudo retirarse (HU-26) mientras tanto.
  select po.trabajadora_id
    into v_trabajadora
    from public.postulaciones po
   where po.id = p_postulacion
     and po.estado = 'pendiente';

  if not found then
    raise exception 'Esta postulación ya no está disponible';
  end if;

  if v_solicitud.inicio <= now() then
    raise exception 'La fecha de esta solicitud ya pasó';
  end if;

  -- Pudo postularse a dos solicitudes con el mismo horario y otro cliente la
  -- eligió primero (HU-12 c3 solo revisa los servicios ya asignados).
  if exists (
    select 1 from public.solicitudes otra
     where otra.trabajadora_id = v_trabajadora
       and otra.estado = 'asignada'
       and otra.id <> v_solicitud.id
       and otra.inicio < v_solicitud.fin
       and otra.fin > v_solicitud.inicio
  ) then
    raise exception 'Esta trabajadora ya tiene un servicio en ese horario';
  end if;

  update public.solicitudes
     set estado         = 'asignada',
         trabajadora_id = v_trabajadora
   where id = v_solicitud.id;

  update public.postulaciones
     set estado = 'aceptada'
   where id = p_postulacion;

  update public.postulaciones
     set estado = 'no_seleccionada'
   where solicitud_id = v_solicitud.id
     and id <> p_postulacion
     and estado = 'pendiente';
end;
$$;

revoke execute on function public.elegir_trabajadora(uuid) from public, anon;
grant execute on function public.elegir_trabajadora(uuid) to authenticated;
