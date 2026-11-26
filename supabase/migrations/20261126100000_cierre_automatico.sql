-- ---------------------------------------------------------------------------
-- HU-17 c3 · Cierre automático a las 48 horas
--
-- Si el cliente no marca el servicio como completado, la base lo hace sola
-- cuando pasan 48 horas desde la hora de fin del servicio. Así el servicio
-- deja de estar "asignado" para siempre y se habilita la calificación.
--
-- La lógica vive en una función y pg_cron la ejecuta cada hora. La función
-- no se expone a la app: solo el job (postgres) puede llamarla.
-- ---------------------------------------------------------------------------
create extension if not exists pg_cron;

create or replace function public.cerrar_servicios_vencidos()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cerrados integer;
begin
  update public.solicitudes
     set estado        = 'completada',
         -- La fecha de cierre es la que corresponde al plazo, no la hora en
         -- que corrió el job: así el chat y la calificación cuentan desde el
         -- momento real en que el servicio debió cerrarse.
         completada_en = fin + interval '48 hours'
   where estado = 'asignada'
     and fin + interval '48 hours' <= now();

  get diagnostics v_cerrados = row_count;
  return v_cerrados;
end;
$$;

revoke all on function public.cerrar_servicios_vencidos() from public;

-- Un solo job, aunque la migración se vuelva a ejecutar.
do $$
begin
  if not exists (
    select 1 from cron.job where jobname = 'cerrar-servicios-vencidos'
  ) then
    perform cron.schedule(
      'cerrar-servicios-vencidos',
      '15 * * * *',
      'select public.cerrar_servicios_vencidos();'
    );
  end if;
end;
$$;
