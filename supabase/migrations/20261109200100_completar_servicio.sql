-- ---------------------------------------------------------------------------
-- HU-17 · Marcar un servicio como completado
--
-- Igual que elegir_trabajadora (HU-15), pasa por una función porque el
-- cliente no puede escribir la columna estado (grant de HD-04):
-- - c1: solo el cliente dueño, con el servicio Asignado y su hora de inicio
--   ya pasada, lo pasa a Completado. Desde ahí se puede calificar
--   (puede_calificar, HU-29 / HU-30) y el chat sigue abierto 7 días (HU-38).
-- - c2: si todavía no ha empezado, la función falla y no cambia nada.
-- ---------------------------------------------------------------------------
create or replace function public.completar_servicio(p_solicitud uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes%rowtype;
begin
  select *
    into v_solicitud
    from public.solicitudes
   where id = p_solicitud
     and cliente_id = (select auth.uid())
     for update;

  if not found then
    raise exception 'No encontramos ese servicio';
  end if;

  if v_solicitud.estado <> 'asignada' then
    raise exception 'Solo puedes completar un servicio asignado';
  end if;

  if v_solicitud.inicio > now() then
    raise exception 'El servicio todavía no ha empezado';
  end if;

  update public.solicitudes
     set estado        = 'completada',
         completada_en = now()
   where id = p_solicitud;
end;
$$;

revoke execute on function public.completar_servicio(uuid) from public, anon;
grant execute on function public.completar_servicio(uuid) to authenticated;
