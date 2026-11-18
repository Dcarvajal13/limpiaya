-- ---------------------------------------------------------------------------
-- Direcciones guardadas del cliente ("Casa", "Casa de mi mamá", "Oficina"…)
--
-- El cliente guarda sus direcciones una vez y, al publicar una solicitud,
-- elige una con un toque en vez de volver a escribir zona y dirección.
--
-- - Son privadas: solo las ve y las cambia su dueño (RLS). Las trabajadoras
--   siguen viendo solo la zona de cada solicitud (vista solicitudes_publicas).
-- - La solicitud guarda su propia copia de zona y dirección, así que borrar
--   o editar una dirección guardada no cambia solicitudes ya publicadas.
-- - Máximo 10 por cliente y sin nombres repetidos.
-- - La dirección del perfil (HU-05) se copia como "Casa" para quien ya la
--   tenía, y de aquí en adelante se copia sola la primera vez que se guarda.
-- ---------------------------------------------------------------------------
create table public.direcciones_cliente (
  id               uuid primary key default gen_random_uuid(),
  cliente_id       uuid not null default auth.uid()
                     references public.clientes (id) on delete cascade,
  nombre           text not null check (char_length(btrim(nombre)) between 1 and 40),
  zona_id          smallint not null references public.zonas (id),
  direccion        text not null check (char_length(direccion) between 5 and 300),
  punto_referencia text check (char_length(punto_referencia) <= 200),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Sin nombres repetidos para el mismo cliente ("Casa" y "casa" cuentan igual).
create unique index direcciones_cliente_nombre_idx
  on public.direcciones_cliente (cliente_id, lower(btrim(nombre)));

create trigger direcciones_cliente_updated_at
  before update on public.direcciones_cliente
  for each row execute function public.set_updated_at();

comment on table public.direcciones_cliente is
  'Direcciones que el cliente guarda para elegirlas al publicar una solicitud.';

-- Máximo 10 direcciones por cliente.
create or replace function public.direcciones_cliente_limite()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if (select count(*) from public.direcciones_cliente d
       where d.cliente_id = new.cliente_id) >= 10 then
    raise exception 'Puedes guardar hasta 10 direcciones';
  end if;
  return new;
end;
$$;

create trigger direcciones_cliente_limite
  before insert on public.direcciones_cliente
  for each row execute function public.direcciones_cliente_limite();

-- Seguridad: cada cliente solo ve y cambia las suyas.
alter table public.direcciones_cliente enable row level security;

revoke all on public.direcciones_cliente from public, anon, authenticated;
grant select, delete on public.direcciones_cliente to authenticated;
grant insert (nombre, zona_id, direccion, punto_referencia)
  on public.direcciones_cliente to authenticated;
grant update (nombre, zona_id, direccion, punto_referencia)
  on public.direcciones_cliente to authenticated;

create policy "direcciones: leer las mías" on public.direcciones_cliente
  for select to authenticated
  using (cliente_id = (select auth.uid()));

create policy "direcciones: crear las mías" on public.direcciones_cliente
  for insert to authenticated
  with check (cliente_id = (select auth.uid()));

create policy "direcciones: editar las mías" on public.direcciones_cliente
  for update to authenticated
  using (cliente_id = (select auth.uid()))
  with check (cliente_id = (select auth.uid()));

create policy "direcciones: borrar las mías" on public.direcciones_cliente
  for delete to authenticated
  using (cliente_id = (select auth.uid()));

-- La dirección del perfil se copia como "Casa" si el cliente todavía no tiene
-- ninguna guardada (la primera vez que completa su perfil).
create or replace function public.copiar_direccion_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.zona_id is not null
     and new.direccion is not null
     and not exists (select 1 from public.direcciones_cliente d
                      where d.cliente_id = new.id) then
    insert into public.direcciones_cliente
      (cliente_id, nombre, zona_id, direccion, punto_referencia)
    values (new.id, 'Casa', new.zona_id, new.direccion, new.punto_referencia);
  end if;
  return new;
end;
$$;

revoke execute on function public.copiar_direccion_perfil() from public, anon, authenticated;

create trigger clientes_copiar_direccion
  after insert or update of zona_id, direccion on public.clientes
  for each row execute function public.copiar_direccion_perfil();

-- Quienes ya tenían su perfil completo arrancan con "Casa".
insert into public.direcciones_cliente
  (cliente_id, nombre, zona_id, direccion, punto_referencia)
select c.id, 'Casa', c.zona_id, c.direccion, c.punto_referencia
  from public.clientes c
 where c.zona_id is not null
   and c.direccion is not null
   and not exists (select 1 from public.direcciones_cliente d
                    where d.cliente_id = c.id);
