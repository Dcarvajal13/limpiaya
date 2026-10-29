-- =============================================================================
-- HD-07 · Datos de prueba para las demos
-- =============================================================================
-- Crea 3 clientes, 5 trabajadoras verificadas, 10 solicitudes en distintas
-- zonas de Caracas y algunas postulaciones, para que cada review muestre la
-- página con contenido realista.
--
-- Cómo usarlo:
--   1. Cambia la contraseña de la línea marcada con «CAMBIA AQUÍ» (no la
--      subas al repositorio) y pásala al equipo por privado.
--   2. Pega todo el archivo en Supabase → SQL Editor y dale a Run.
--
-- Se puede correr las veces que haga falta: primero borra las cuentas de
-- prueba anteriores (todas terminan en @demo.limpiaya.app) y todo lo que
-- cuelga de ellas, y las vuelve a crear (criterio 2: no se duplican).
-- Las fechas de las solicitudes se calculan desde hoy, así que siempre
-- quedan en el futuro.
--
-- No es una migración: no lo apliques con "supabase db push".
-- =============================================================================

-- Crea una cuenta como si se hubiera registrado en la app: el trigger
-- crear_perfil_nuevo_usuario arma su perfil a partir de los metadatos.
create or replace function pg_temp.crear_usuario_demo(
  p_email    text,
  p_password text,
  p_nombre   text,
  p_telefono text,
  p_rol      text
)
returns uuid
language plpgsql
as $$
declare
  v_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    -- En nulo, Supabase Auth falla al iniciar sesión con estas cuentas.
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) values (
    '00000000-0000-0000-0000-000000000000', v_id, 'authenticated',
    'authenticated', p_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    now(),
    '{"provider": "email", "providers": ["email"]}',
    jsonb_build_object('nombre', p_nombre, 'telefono', p_telefono, 'rol', p_rol),
    now(), now(),
    '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_id, v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', p_email, 'email_verified', true),
    'email', now(), now(), now()
  );

  return v_id;
end;
$$;

-- Zona por nombre (el catálogo está en la migración inicial).
create or replace function pg_temp.zona(p_nombre text)
returns smallint
language sql
as $$ select id from public.zonas where nombre = p_nombre $$;

-- Fecha futura en hora de Caracas: dentro de p_dias días, a la hora p_hora.
create or replace function pg_temp.dentro_de(p_dias int, p_hora numeric)
returns timestamptz
language sql
as $$
  select (date_trunc('day', now() at time zone 'America/Caracas')
          + make_interval(days => p_dias, mins => (p_hora * 60)::int))
         at time zone 'America/Caracas'
$$;

do $$
declare
  v_password text := 'CAMBIA_ESTA_CLAVE'; -- «CAMBIA AQUÍ» (mínimo 8 caracteres)

  -- Clientes
  c_maria  uuid;
  c_luis   uuid;
  c_gaby   uuid;
  -- Trabajadoras
  t_carmen    uuid;
  t_yelitza   uuid;
  t_marisol   uuid;
  t_andreina  uuid;
  t_josefina  uuid;
  -- Solicitudes que reciben postulaciones
  s1 uuid; s2 uuid; s3 uuid; s5 uuid; s7 uuid; s9 uuid;
begin
  if v_password = 'CAMBIA_ESTA_CLAVE' or char_length(v_password) < 8 then
    raise exception 'Cambia la contraseña de prueba (línea «CAMBIA AQUÍ») antes de correr el script';
  end if;

  -- Criterio 2: empezar de cero. Al borrar las cuentas se borran en cascada
  -- sus perfiles, solicitudes, postulaciones, verificaciones y zonas.
  delete from auth.users where email like '%@demo.limpiaya.app';

  -- ---------------------------------------------------------------------------
  -- Clientes (3)
  -- ---------------------------------------------------------------------------
  c_maria := pg_temp.crear_usuario_demo('maria@demo.limpiaya.app', v_password,
    'María Alejandra Rodríguez', '0414-5550101', 'cliente');
  c_luis := pg_temp.crear_usuario_demo('luis@demo.limpiaya.app', v_password,
    'Luis Fernández', '0424-5550102', 'cliente');
  c_gaby := pg_temp.crear_usuario_demo('gabriela@demo.limpiaya.app', v_password,
    'Gabriela Méndez', '0412-5550103', 'cliente');

  update public.clientes set zona_id = pg_temp.zona('Los Palos Grandes'),
         direccion = '4ta avenida, edificio Ávila, piso 6',
         punto_referencia = 'Frente a la panadería, reja color crema'
   where id = c_maria;
  update public.clientes set zona_id = pg_temp.zona('El Cafetal'),
         direccion = 'Calle Mucuchíes, quinta Los Pinos',
         punto_referencia = 'Al lado del abasto'
   where id = c_luis;
  update public.clientes set zona_id = pg_temp.zona('Sabana Grande'),
         direccion = 'Calle Villaflor, residencias Sabana, apto 3B',
         punto_referencia = 'Cerca de la estación Plaza Venezuela'
   where id = c_gaby;

  -- ---------------------------------------------------------------------------
  -- Trabajadoras (5), todas con la identidad verificada
  -- ---------------------------------------------------------------------------
  t_carmen := pg_temp.crear_usuario_demo('carmen@demo.limpiaya.app', v_password,
    'Carmen Pérez', '0416-5550201', 'trabajadora');
  t_yelitza := pg_temp.crear_usuario_demo('yelitza@demo.limpiaya.app', v_password,
    'Yelitza Rojas', '0414-5550202', 'trabajadora');
  t_marisol := pg_temp.crear_usuario_demo('marisol@demo.limpiaya.app', v_password,
    'Marisol Gómez', '0424-5550203', 'trabajadora');
  t_andreina := pg_temp.crear_usuario_demo('andreina@demo.limpiaya.app', v_password,
    'Andreína Silva', '0412-5550204', 'trabajadora');
  t_josefina := pg_temp.crear_usuario_demo('josefina@demo.limpiaya.app', v_password,
    'Josefina Mendoza', '0426-5550205', 'trabajadora');

  update public.trabajadoras set experiencia_anios = 15, tarifa_referencia = 6,
         descripcion = 'Soy responsable, puntual y detallista. Me gusta que cada espacio quede ordenado y agradable para la familia.'
   where id = t_carmen;
  update public.trabajadoras set experiencia_anios = 7, tarifa_referencia = 5,
         descripcion = 'Vivo cerca de Baruta y puedo llevar mis propios productos. Tengo experiencia con mascotas.'
   where id = t_yelitza;
  update public.trabajadoras set experiencia_anios = 4,
         descripcion = 'Me encanta el orden. Trabajo con calma y cuido mucho los detalles.'
   where id = t_marisol;
  update public.trabajadoras set experiencia_anios = 10, tarifa_referencia = 7,
         descripcion = 'Especialista en limpiezas profundas y después de mudanzas.'
   where id = t_andreina;
  update public.trabajadoras set experiencia_anios = 20, tarifa_referencia = 8,
         descripcion = 'Muchos años cuidando casas en El Hatillo. Plancho muy bien.'
   where id = t_josefina;

  insert into public.trabajadora_zonas (trabajadora_id, zona_id)
  select t, pg_temp.zona(z)
    from (values
      (t_carmen, 'Los Palos Grandes'), (t_carmen, 'Altamira'), (t_carmen, 'La Castellana'),
      (t_yelitza, 'El Cafetal'), (t_yelitza, 'Santa Fe'), (t_yelitza, 'Las Mercedes'),
      (t_marisol, 'Los Dos Caminos'), (t_marisol, 'Sebucán'), (t_marisol, 'Los Palos Grandes'),
      (t_andreina, 'Sabana Grande'), (t_andreina, 'Los Chaguaramos'), (t_andreina, 'El Paraíso'),
      (t_josefina, 'La Lagunita'), (t_josefina, 'La Boyera'), (t_josefina, 'El Cafetal')
    ) as x(t, z);

  insert into public.trabajadora_servicios (trabajadora_id, tipo)
  select t, s::public.tipo_limpieza
    from (values
      (t_carmen, 'general'), (t_carmen, 'profunda'), (t_carmen, 'planchado'),
      (t_yelitza, 'general'), (t_yelitza, 'post_mudanza'),
      (t_marisol, 'general'), (t_marisol, 'planchado'),
      (t_andreina, 'profunda'), (t_andreina, 'post_mudanza'), (t_andreina, 'general'),
      (t_josefina, 'general'), (t_josefina, 'planchado')
    ) as x(t, s);

  -- Verificación aprobada: el trigger sincronizar_verificacion las deja
  -- "Identidad verificada" y así se pueden postular (HU-12 c4).
  insert into public.verificaciones
    (trabajadora_id, cedula_path, selfie_path, estado, revisada_en)
  select t, t || '/cedula-demo.jpg', t || '/selfie-demo.jpg', 'aprobada', now()
    from unnest(array[t_carmen, t_yelitza, t_marisol, t_andreina, t_josefina]) as t;

  -- ---------------------------------------------------------------------------
  -- Solicitudes (10) en varias zonas, siempre a futuro
  -- ---------------------------------------------------------------------------
  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, punto_referencia,
         inicio, horas_estimadas, pago_ofrecido, metodo_pago, habitaciones, banos,
         tiene_mascotas, productos_por, notas)
  values (c_maria, 'general', pg_temp.zona('Los Palos Grandes'), '4ta avenida, edificio Ávila, piso 6',
          'Frente a la panadería, reja color crema', pg_temp.dentro_de(3, 9), 4, 30, 'pago_movil',
          3, 2, false, 'cliente', 'Cocina y dos baños, por favor.')
  returning id into s1;

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_maria, 'planchado', pg_temp.zona('Los Palos Grandes'), '4ta avenida, edificio Ávila, piso 6',
          pg_temp.dentro_de(6, 14), 3, 24, 'transferencia', 3, 2, false, 'cliente')
  returning id into s2;

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por, notas)
  values (c_luis, 'profunda', pg_temp.zona('El Cafetal'), 'Calle Mucuchíes, quinta Los Pinos',
          pg_temp.dentro_de(4, 8), 6, 48, 'efectivo_usd', 4, 3, true, 'trabajadora',
          'Tenemos un perro tranquilo.')
  returning id into s3;

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_luis, 'general', pg_temp.zona('Santa Fe'), 'Avenida Principal de Santa Fe, residencias Mónaco',
          pg_temp.dentro_de(9, 10), 4, 32, 'pago_movil', 2, 2, false, 'cliente');

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_gaby, 'post_mudanza', pg_temp.zona('Sabana Grande'), 'Calle Villaflor, residencias Sabana, apto 3B',
          pg_temp.dentro_de(5, 7.5), 8, 60, 'pago_movil', 2, 1, false, 'trabajadora')
  returning id into s5;

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_gaby, 'general', pg_temp.zona('Los Chaguaramos'), 'Avenida Las Ciencias, edificio Caura',
          pg_temp.dentro_de(11, 9), 3, 22, 'efectivo_bs', 1, 1, true, 'cliente');

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_maria, 'general', pg_temp.zona('Altamira'), 'Avenida San Juan Bosco, edificio Miranda',
          pg_temp.dentro_de(8, 8.5), 5, 36, 'pago_movil', 3, 2, false, 'cliente')
  returning id into s7;

  insert into public.solicitudes (cliente_id, tipo, zona_id, direccion, inicio, horas_estimadas,
         pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas, productos_por)
  values (c_luis, 'planchado', pg_temp.zona('La Lagunita'), 'Calle El Lago, casa 14',
          pg_temp.dentro_de(7, 15), 3, 21, 'transferencia', 4, 3, false, 'cliente');

  -- Una ya Asignada (Carmen con María) para que se vea "Próximo servicio".
  insert into public.solicitudes (cliente_id, trabajadora_id, estado, tipo, zona_id, direccion,
         inicio, horas_estimadas, pago_ofrecido, metodo_pago, habitaciones, banos,
         tiene_mascotas, productos_por)
  values (c_maria, t_carmen, 'asignada', 'profunda', pg_temp.zona('Los Palos Grandes'),
          '4ta avenida, edificio Ávila, piso 6', pg_temp.dentro_de(2, 8.5), 5, 36, 'pago_movil',
          3, 2, false, 'cliente')
  returning id into s9;

  -- Una Cancelada, con su motivo (HU-10).
  insert into public.solicitudes (cliente_id, estado, tipo, zona_id, direccion, inicio,
         horas_estimadas, pago_ofrecido, metodo_pago, habitaciones, banos, tiene_mascotas,
         productos_por, cancelada_en, cancelada_por, motivo_cancelacion)
  values (c_gaby, 'cancelada', 'general', pg_temp.zona('Sabana Grande'),
          'Calle Villaflor, residencias Sabana, apto 3B', pg_temp.dentro_de(10, 9), 4, 28,
          'pago_movil', 2, 1, false, 'cliente', now(), c_gaby, 'Cambio de planes');

  -- ---------------------------------------------------------------------------
  -- Postulaciones (de trabajadoras que trabajan en esa zona)
  -- ---------------------------------------------------------------------------
  insert into public.postulaciones (solicitud_id, trabajadora_id, mensaje, estado)
  values
    (s1, t_carmen,  'Tengo disponibilidad ese día y conozco la zona.', 'pendiente'),
    (s1, t_marisol, 'Será un gusto ayudarte con tu casa.', 'pendiente'),
    (s2, t_carmen,  'Plancho con mucho cuidado.', 'pendiente'),
    (s3, t_yelitza, 'Puedo llevar mis productos y me llevo bien con perros.', 'pendiente'),
    (s3, t_josefina, null, 'pendiente'),
    (s5, t_andreina, 'Tengo experiencia en mudanzas, llevo todo lo necesario.', 'pendiente'),
    (s7, t_carmen,  null, 'pendiente'),
    (s9, t_carmen,  'Allí estaré puntual.', 'aceptada');

  raise notice 'Listo: 3 clientes, 5 trabajadoras verificadas y 10 solicitudes de prueba.';
end;
$$;
