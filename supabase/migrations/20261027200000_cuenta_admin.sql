-- ---------------------------------------------------------------------------
-- HD-06 · Crear el rol Administrador
--
-- El rol 'admin' ya existe (esquema inicial) y el registro público no lo
-- permite (crear_perfil_nuevo_usuario, criterio 2). Falta la cuenta inicial:
-- se crea en el Dashboard de Supabase y luego se convierte en admin con esta
-- función. El trigger de registro la deja como cliente, por eso se borra su
-- fila de clientes.
--
-- Uso (solo desde el SQL Editor del Dashboard, nunca desde la app):
--   select public.hacer_admin('correo-de-la-cuenta@ejemplo.com');
-- ---------------------------------------------------------------------------
create or replace function public.hacer_admin(p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id  uuid;
  v_rol public.rol_usuario;
begin
  select u.id into v_id
    from auth.users u
   where lower(u.email) = lower(trim(p_email));

  if v_id is null then
    raise exception 'No existe una cuenta con el correo %', p_email;
  end if;

  select p.rol into v_rol from public.perfiles p where p.id = v_id;

  if v_rol = 'admin' then
    return; -- ya es admin
  end if;

  -- Borrar la fila de clientes borra en cascada sus solicitudes, así que solo
  -- se aceptan cuentas nuevas: cliente y sin ninguna solicitud.
  if v_rol is distinct from 'cliente'
     or exists (select 1 from public.solicitudes s where s.cliente_id = v_id) then
    raise exception 'Solo se puede convertir en admin una cuenta nueva creada desde el Dashboard';
  end if;

  delete from public.clientes where id = v_id;
  update public.perfiles set rol = 'admin' where id = v_id;
end;
$$;

-- Supabase da permiso de ejecutar a anon y authenticated en cada función
-- nueva. Se le quita: nadie puede hacerse admin desde la app.
revoke execute on function public.hacer_admin(text) from public, anon, authenticated;
