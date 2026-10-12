-- =============================================================================
-- LimpiaYa · Migración 1: esquema inicial (HD-03)
-- Tablas, tipos, índices y datos de referencia (zonas de Caracas).
-- Las políticas de seguridad (RLS) están en la migración 2.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------------
create type public.rol_usuario as enum ('cliente', 'trabajadora', 'admin');

create type public.tipo_limpieza as enum ('general', 'profunda', 'post_mudanza', 'planchado');

create type public.metodo_pago as enum ('pago_movil', 'efectivo_usd', 'efectivo_bs', 'transferencia');

create type public.quien_pone_productos as enum ('cliente', 'trabajadora');

-- Una "solicitud" asignada es lo que en las HU se llama "servicio".
create type public.estado_solicitud as enum ('publicada', 'asignada', 'completada', 'cancelada');

create type public.estado_postulacion as enum (
  'pendiente', 'aceptada', 'no_seleccionada', 'retirada', 'solicitud_cancelada'
);

create type public.estado_verificacion as enum ('pendiente', 'en_revision', 'aprobada', 'rechazada');

create type public.motivo_calificacion_baja as enum (
  'pago_incompleto', 'trato', 'condiciones_distintas', 'otro'
);

-- ---------------------------------------------------------------------------
-- Utilidad: mantener updated_at
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Zonas (datos de referencia)
-- ---------------------------------------------------------------------------
create table public.zonas (
  id        smallint generated always as identity primary key,
  nombre    text not null,
  municipio text not null,
  unique (nombre, municipio)
);

comment on table public.zonas is 'Zonas de Caracas donde se ofrece el servicio. Se usan en perfiles y solicitudes.';

-- ---------------------------------------------------------------------------
-- Perfiles (1 a 1 con auth.users). Se crea solo con un trigger al registrarse.
-- ---------------------------------------------------------------------------
create table public.perfiles (
  id         uuid primary key references auth.users (id) on delete cascade,
  rol        public.rol_usuario not null,
  nombre     text not null check (char_length(trim(nombre)) between 2 and 80),
  -- Nulo solo para cuentas creadas desde el Dashboard. La app siempre lo pide (HU-01).
  telefono   text check (telefono ~ '^04[0-9]{2}-[0-9]{7}$'),
  -- Ruta dentro del bucket "avatars", p. ej. '<uid>/avatar.jpg'
  foto_path  text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.perfiles.telefono is 'Privado: nunca se muestra a la otra parte (decisión del equipo, HU-06 criterio 4).';

create trigger perfiles_updated_at
  before update on public.perfiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Datos propios del cliente (HU-05)
-- ---------------------------------------------------------------------------
create table public.clientes (
  id               uuid primary key references public.perfiles (id) on delete cascade,
  zona_id          smallint references public.zonas (id),
  direccion        text check (char_length(direccion) between 5 and 300),
  punto_referencia text check (char_length(punto_referencia) <= 200),
  updated_at       timestamptz not null default now()
);

create trigger clientes_updated_at
  before update on public.clientes
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Datos propios de la trabajadora (HU-04)
-- ---------------------------------------------------------------------------
create table public.trabajadoras (
  id                uuid primary key references public.perfiles (id) on delete cascade,
  experiencia_anios smallint not null default 0 check (experiencia_anios between 0 and 60),
  tarifa_referencia numeric(8, 2) check (tarifa_referencia > 0),
  descripcion       text check (char_length(descripcion) <= 500),
  -- Lo mantiene un trigger a partir de la tabla verificaciones. La app no puede escribirlo.
  verificacion      public.estado_verificacion not null default 'pendiente',
  updated_at        timestamptz not null default now()
);

create trigger trabajadoras_updated_at
  before update on public.trabajadoras
  for each row execute function public.set_updated_at();

create table public.trabajadora_zonas (
  trabajadora_id uuid not null references public.trabajadoras (id) on delete cascade,
  zona_id        smallint not null references public.zonas (id),
  primary key (trabajadora_id, zona_id)
);

create index trabajadora_zonas_zona_idx on public.trabajadora_zonas (zona_id);

create table public.trabajadora_servicios (
  trabajadora_id uuid not null references public.trabajadoras (id) on delete cascade,
  tipo           public.tipo_limpieza not null,
  primary key (trabajadora_id, tipo)
);

-- ---------------------------------------------------------------------------
-- Solicitudes / servicios (HU-07 a HU-17, HU-28, HU-43, HU-52)
-- ---------------------------------------------------------------------------
create table public.solicitudes (
  id                 uuid primary key default gen_random_uuid(),
  cliente_id         uuid not null references public.clientes (id) on delete cascade,
  trabajadora_id     uuid references public.trabajadoras (id),
  estado             public.estado_solicitud not null default 'publicada',

  tipo               public.tipo_limpieza not null,
  zona_id            smallint not null references public.zonas (id),
  -- Privadas: solo las ven el cliente y la trabajadora asignada (HU-05 c3, HU-45 c2).
  direccion          text not null check (char_length(direccion) between 5 and 300),
  punto_referencia   text check (char_length(punto_referencia) <= 200),

  inicio             timestamptz not null,
  horas_estimadas    numeric(3, 1) not null check (horas_estimadas > 0 and horas_estimadas <= 12),
  fin                timestamptz not null, -- lo calcula el trigger: inicio + horas_estimadas

  -- Monto que recibe la trabajadora, en USD. La tarifa de LimpiaYa (10 %) se calcula aparte (HU-52).
  pago_ofrecido      numeric(8, 2) not null check (pago_ofrecido > 0),
  metodo_pago        public.metodo_pago not null,

  habitaciones       smallint not null default 1 check (habitaciones between 0 and 20),
  banos              smallint not null default 1 check (banos between 0 and 20),
  tiene_mascotas     boolean not null default false,
  productos_por      public.quien_pone_productos not null,
  notas              text check (char_length(notas) <= 500),

  completada_en      timestamptz,
  cancelada_en       timestamptz,
  cancelada_por      uuid references public.perfiles (id),
  motivo_cancelacion text check (char_length(motivo_cancelacion) <= 300),
  cancelacion_tardia boolean not null default false, -- < 24 h antes (HU-28 c2)

  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  constraint asignada_requiere_trabajadora
    check (estado not in ('asignada', 'completada') or trabajadora_id is not null)
);

create index solicitudes_disponibles_idx on public.solicitudes (estado, zona_id, inicio);
create index solicitudes_cliente_idx on public.solicitudes (cliente_id, inicio desc);
create index solicitudes_trabajadora_idx on public.solicitudes (trabajadora_id, inicio desc);

create or replace function public.solicitudes_validar_fechas()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.fin := new.inicio + make_interval(mins => (new.horas_estimadas * 60)::int);

  if (tg_op = 'INSERT' or new.inicio is distinct from old.inicio) and new.inicio <= now() then
    raise exception 'La fecha debe ser futura';
  end if;

  return new;
end;
$$;

create trigger solicitudes_fechas
  before insert or update of inicio, horas_estimadas on public.solicitudes
  for each row execute function public.solicitudes_validar_fechas();

create trigger solicitudes_updated_at
  before update on public.solicitudes
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Postulaciones (HU-12, HU-13, HU-14, HU-26)
-- ---------------------------------------------------------------------------
create table public.postulaciones (
  id             uuid primary key default gen_random_uuid(),
  solicitud_id   uuid not null references public.solicitudes (id) on delete cascade,
  trabajadora_id uuid not null references public.trabajadoras (id) on delete cascade,
  mensaje        text check (char_length(mensaje) <= 300),
  estado         public.estado_postulacion not null default 'pendiente',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Una sola postulación activa por trabajadora y solicitud.
-- Si la retira, puede volver a postularse (HU-26 c3): queda una fila nueva.
create unique index postulaciones_una_activa_idx
  on public.postulaciones (solicitud_id, trabajadora_id)
  where estado in ('pendiente', 'aceptada');

create index postulaciones_trabajadora_idx on public.postulaciones (trabajadora_id, created_at desc);

create trigger postulaciones_updated_at
  before update on public.postulaciones
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Calificaciones (HU-29, HU-30)
-- ---------------------------------------------------------------------------
create table public.calificaciones (
  id              uuid primary key default gen_random_uuid(),
  solicitud_id    uuid not null references public.solicitudes (id) on delete cascade,
  autor_id        uuid not null references public.perfiles (id) on delete cascade,
  destinatario_id uuid not null references public.perfiles (id) on delete cascade,
  estrellas       smallint not null check (estrellas between 1 and 5),
  comentario      text check (char_length(comentario) <= 500),
  motivo          public.motivo_calificacion_baja, -- obligatorio en la app si la trabajadora pone 1 o 2 (HU-30 c2)
  created_at      timestamptz not null default now(),
  unique (solicitud_id, autor_id),
  check (autor_id <> destinatario_id)
);

create index calificaciones_destinatario_idx on public.calificaciones (destinatario_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Verificaciones de identidad (HU-21, HU-33)
-- ---------------------------------------------------------------------------
create table public.verificaciones (
  id             uuid primary key default gen_random_uuid(),
  trabajadora_id uuid not null references public.trabajadoras (id) on delete cascade,
  -- Rutas dentro del bucket privado "verificaciones": '<uid>/<archivo>'
  cedula_path    text not null,
  selfie_path    text not null,
  estado         public.estado_verificacion not null default 'en_revision'
                 check (estado <> 'pendiente'),
  motivo_rechazo text check (char_length(motivo_rechazo) <= 300),
  revisada_por   uuid references public.perfiles (id),
  revisada_en    timestamptz,
  created_at     timestamptz not null default now(),
  constraint rechazo_requiere_motivo
    check (estado <> 'rechazada' or char_length(trim(coalesce(motivo_rechazo, ''))) > 0)
);

-- Solo una verificación en revisión a la vez por trabajadora.
create unique index verificaciones_una_en_revision_idx
  on public.verificaciones (trabajadora_id)
  where estado = 'en_revision';

create index verificaciones_cola_idx on public.verificaciones (estado, created_at);

-- Copia el estado de la verificación más reciente a trabajadoras.verificacion
create or replace function public.sincronizar_verificacion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.trabajadoras
     set verificacion = new.estado
   where id = new.trabajadora_id;
  return new;
end;
$$;

create trigger verificaciones_sincronizar
  after insert or update of estado on public.verificaciones
  for each row execute function public.sincronizar_verificacion();

-- ---------------------------------------------------------------------------
-- Mensajes del chat (HU-38)
-- ---------------------------------------------------------------------------
create table public.mensajes (
  id           bigint generated always as identity primary key,
  solicitud_id uuid not null references public.solicitudes (id) on delete cascade,
  autor_id     uuid not null references public.perfiles (id) on delete cascade,
  contenido    text not null check (char_length(trim(contenido)) between 1 and 500),
  created_at   timestamptz not null default now()
);

create index mensajes_chat_idx on public.mensajes (solicitud_id, created_at);

-- ---------------------------------------------------------------------------
-- Datos de referencia: zonas de Caracas (el equipo puede ampliarlas)
-- ---------------------------------------------------------------------------
insert into public.zonas (nombre, municipio) values
  -- Baruta
  ('Las Mercedes', 'Baruta'),
  ('Santa Fe', 'Baruta'),
  ('El Cafetal', 'Baruta'),
  ('Prados del Este', 'Baruta'),
  ('La Trinidad', 'Baruta'),
  ('Los Samanes', 'Baruta'),
  ('Colinas de Bello Monte', 'Baruta'),
  ('Alto Prado', 'Baruta'),
  ('Baruta (casco)', 'Baruta'),
  -- Chacao
  ('Altamira', 'Chacao'),
  ('Los Palos Grandes', 'Chacao'),
  ('La Castellana', 'Chacao'),
  ('El Rosal', 'Chacao'),
  ('Campo Alegre', 'Chacao'),
  ('Country Club', 'Chacao'),
  ('Chacao (casco)', 'Chacao'),
  -- El Hatillo
  ('El Hatillo (pueblo)', 'El Hatillo'),
  ('La Lagunita', 'El Hatillo'),
  ('Los Naranjos', 'El Hatillo'),
  ('La Boyera', 'El Hatillo'),
  ('Alto Hatillo', 'El Hatillo'),
  -- Sucre
  ('Los Dos Caminos', 'Sucre'),
  ('La Urbina', 'Sucre'),
  ('Boleíta', 'Sucre'),
  ('Los Ruices', 'Sucre'),
  ('Terrazas del Ávila', 'Sucre'),
  ('Macaracuay', 'Sucre'),
  ('Santa Eduvigis', 'Sucre'),
  ('Sebucán', 'Sucre'),
  ('Petare', 'Sucre'),
  -- Libertador
  ('Sabana Grande', 'Libertador'),
  ('Los Chaguaramos', 'Libertador'),
  ('El Paraíso', 'Libertador'),
  ('La Candelaria', 'Libertador'),
  ('San Bernardino', 'Libertador'),
  ('Santa Mónica', 'Libertador'),
  ('Montalbán', 'Libertador'),
  ('La Florida', 'Libertador'),
  ('El Valle', 'Libertador'),
  ('Centro', 'Libertador');
