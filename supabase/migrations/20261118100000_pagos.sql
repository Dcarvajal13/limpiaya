-- ---------------------------------------------------------------------------
-- E9 · Cobrar un servicio
--
-- El pago deja de vivir en memoria: queda una fila en `pagos`, una por
-- solicitud. Como el cliente no puede escribir las columnas del cobro (los
-- montos los calcula la base a partir de `solicitudes.pago_ofrecido`), el
-- cobro pasa por esta función, igual que elegir_trabajadora (HU-15):
-- - c1: solo el cliente dueño puede pagar, con el servicio Asignado (o ya
--   Completado, para no bloquear a quien completó antes de pagar).
-- - c2: la tarifa es la misma de HU-52 (10% del pago a la trabajadora) y se
--   redondea a centavos, como SolicitudService.tarifa.
-- - c3: si la solicitud ya tiene pago, devuelve ese mismo pago (idempotente):
--   dos clics o dos pestañas no cobran dos veces.
-- - c4: el cobro se registra aprobado. La pasarela es de mentira: no se mueve
--   dinero, pero el pago sí existe y se puede volver a leer.
-- ---------------------------------------------------------------------------
create type public.estado_pago as enum ('aprobado', 'rechazado');

-- Referencias legibles y sin repetirse (PG-000001, PG-000002…).
create sequence public.pagos_referencia_seq;

create table public.pagos (
  id                uuid primary key default gen_random_uuid(),
  solicitud_id      uuid not null unique
                    references public.solicitudes (id) on delete cascade,
  pago_trabajadora  numeric(8, 2) not null check (pago_trabajadora > 0),
  tarifa            numeric(8, 2) not null check (tarifa >= 0),
  total             numeric(8, 2) not null
                    check (total = pago_trabajadora + tarifa),
  metodo            public.metodo_pago not null,
  estado            public.estado_pago not null default 'aprobado',
  referencia        text not null,
  motivo_rechazo    text,
  creado_en         timestamptz not null default now(),
  check (estado <> 'rechazado' or char_length(trim(coalesce(motivo_rechazo, ''))) > 0)
);

create index pagos_solicitud_idx on public.pagos (solicitud_id);

alter table public.pagos enable row level security;

-- Solo el cliente dueño y la trabajadora asignada leen el cobro.
create policy "pagos: leer los de mi servicio"
  on public.pagos for select
  to authenticated
  using (
    exists (
      select 1
        from public.solicitudes s
       where s.id = solicitud_id
         and (s.cliente_id = (select auth.uid())
              or s.trabajadora_id = (select auth.uid()))
    )
  );

grant select on public.pagos to authenticated;

create or replace function public.pagar_servicio(p_solicitud uuid)
returns public.pagos
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes%rowtype;
  v_pago      public.pagos%rowtype;
  v_tarifa    numeric(8, 2);
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

  if v_solicitud.estado not in ('asignada', 'completada') then
    raise exception 'Solo puedes pagar un servicio asignado';
  end if;

  -- Idempotente: si ya se cobró, se devuelve el mismo pago.
  select *
    into v_pago
    from public.pagos
   where solicitud_id = p_solicitud;

  if found then
    return v_pago;
  end if;

  -- Misma tarifa que SolicitudService.tarifa (HU-52): 10% redondeado.
  v_tarifa := round(v_solicitud.pago_ofrecido * 0.10, 2);

  insert into public.pagos (
    solicitud_id,
    pago_trabajadora,
    tarifa,
    total,
    metodo,
    estado,
    referencia
  )
  values (
    p_solicitud,
    v_solicitud.pago_ofrecido,
    v_tarifa,
    v_solicitud.pago_ofrecido + v_tarifa,
    v_solicitud.metodo_pago,
    'aprobado',
    'PG-' || lpad(nextval('public.pagos_referencia_seq')::text, 6, '0')
  )
  returning * into v_pago;

  return v_pago;
end;
$$;

revoke execute on function public.pagar_servicio(uuid) from public, anon;
grant execute on function public.pagar_servicio(uuid) to authenticated;
