-- ---------------------------------------------------------------------------
-- Verificación de identidad también para los clientes
--
-- Hasta ahora solo la trabajadora verificaba su identidad (HU-21) para poder
-- postularse. Ahora el cliente también: sube su cédula y una selfie, el
-- admin la revisa (HU-33) y, hasta que esté aprobada, no puede publicar
-- solicitudes.
--
-- - verificaciones.trabajadora_id pasa a llamarse usuario_id y apunta a
--   perfiles: la misma tabla sirve para clientes y trabajadoras.
-- - clientes.verificacion: igual que trabajadoras.verificacion, la mantiene
--   el trigger sincronizar_verificacion y la app no la puede escribir.
-- - Los clientes que ya existían quedan aprobados (decisión del equipo, para
--   no romper las cuentas de prueba). Los nuevos empiezan en "pendiente".
-- - mi_sesion() devuelve la verificación también para el cliente.
-- - Solo un cliente con la identidad aprobada puede publicar (RLS).
-- - perfiles_publicos suma `verificada` para que la trabajadora vea si el
--   cliente está verificado.
-- ---------------------------------------------------------------------------

-- 1. El estado de verificación del cliente
alter table public.clientes
  add column verificacion public.estado_verificacion not null default 'pendiente';

comment on column public.clientes.verificacion is
  'Lo mantiene el trigger sincronizar_verificacion. La app no puede escribirlo.';

update public.clientes set verificacion = 'aprobada';

-- 2. Las verificaciones son de cualquier usuario (cliente o trabajadora)
alter table public.verificaciones
  drop constraint if exists verificaciones_trabajadora_id_fkey;

alter table public.verificaciones rename column trabajadora_id to usuario_id;

alter table public.verificaciones
  add constraint verificaciones_usuario_id_fkey
  foreign key (usuario_id) references public.perfiles (id) on delete cascade;

-- El admin no se verifica: solo clientes y trabajadoras.
create or replace function public.verificaciones_validar_rol()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.perfiles p
     where p.id = new.usuario_id
       and p.rol in ('cliente', 'trabajadora')
  ) then
    raise exception 'Solo clientes y trabajadoras verifican su identidad';
  end if;
  return new;
end;
$$;

revoke execute on function public.verificaciones_validar_rol() from public, anon, authenticated;

create trigger verificaciones_validar_rol
  before insert on public.verificaciones
  for each row execute function public.verificaciones_validar_rol();

alter policy "verificaciones: la trabajadora envía la suya" on public.verificaciones
  rename to "verificaciones: cada quien envía la suya";

-- 3. Copia el estado de la verificación más reciente a la trabajadora o al
-- cliente (solo una de las dos filas existe).
create or replace function public.sincronizar_verificacion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.trabajadoras
     set verificacion = new.estado
   where id = new.usuario_id;

  update public.clientes
     set verificacion = new.estado
   where id = new.usuario_id;

  return new;
end;
$$;

-- 4. mi_sesion(): igual que antes, pero la verificación sale también para el
-- cliente.
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
    )
  )
  from public.perfiles p
  where p.id = (select auth.uid());
$$;

-- 5. Solo el cliente con la identidad aprobada publica solicitudes.
drop policy "solicitudes: el cliente publica" on public.solicitudes;

create policy "solicitudes: el cliente verificado publica" on public.solicitudes
  for insert to authenticated
  with check (
    cliente_id = (select auth.uid())
    and exists (
      select 1 from public.clientes c
       where c.id = (select auth.uid())
         and c.verificacion = 'aprobada'
    )
  );

-- 6. La trabajadora ve si el cliente está verificado (columna al final).
create or replace view public.perfiles_publicos as
select p.id,
       p.rol,
       p.nombre,
       p.foto_path,
       coalesce(coalesce(t.verificacion, c.verificacion) = 'aprobada', false)
         as verificada
  from public.perfiles p
  left join public.trabajadoras t on t.id = p.id
  left join public.clientes c on c.id = p.id;
