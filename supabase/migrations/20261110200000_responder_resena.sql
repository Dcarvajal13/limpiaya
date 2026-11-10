-- ---------------------------------------------------------------------------
-- HU-31 · Responder a una reseña
--
-- Quien recibió una reseña ya visible puede contestarla una sola vez y
-- editar su respuesta después:
-- - c1: la respuesta aparece debajo de la reseña en el perfil (la vista
--   resenas_publicas suma las columnas respuesta y respuesta_en).
-- - c2: una respuesta por reseña (la llave primaria es la calificación);
--   volver a responder la reemplaza.
-- - c3: hasta 300 caracteres ("La respuesta puede tener hasta 300
--   caracteres").
-- Igual que HU-15, HU-17 y HU-28, se escribe por una función: la tabla no
-- tiene permisos de escritura para la app.
-- ---------------------------------------------------------------------------
create table public.respuestas_resenas (
  calificacion_id uuid primary key references public.calificaciones (id) on delete cascade,
  autor_id        uuid not null references public.perfiles (id) on delete cascade,
  texto           text not null check (char_length(trim(texto)) between 1 and 300),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.respuestas_resenas is
  'HU-31: respuesta de quien recibió la reseña. Una por reseña; se puede editar.';

create trigger respuestas_resenas_updated_at
  before update on public.respuestas_resenas
  for each row execute function public.set_updated_at();

alter table public.respuestas_resenas enable row level security;

revoke all on public.respuestas_resenas from public, anon, authenticated;
grant select on public.respuestas_resenas to authenticated;

-- Cada quien lee las suyas; las demás se ven en la vista resenas_publicas.
create policy "respuestas_resenas: leer las propias" on public.respuestas_resenas
  for select to authenticated
  using (autor_id = (select auth.uid()) or (select public.es_admin()));

create or replace function public.responder_resena(
  p_calificacion uuid,
  p_texto        text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_texto text := trim(coalesce(p_texto, ''));
begin
  if v_texto = '' then
    raise exception 'Escribe tu respuesta';
  end if;

  if char_length(v_texto) > 300 then
    raise exception 'La respuesta puede tener hasta 300 caracteres';
  end if;

  -- Solo quien la recibió, y solo cuando la reseña ya se muestra (HU-29 c4).
  if not exists (
    select 1 from public.resenas_publicas r
     where r.id = p_calificacion
       and r.destinatario_id = (select auth.uid())
  ) then
    raise exception 'Solo puedes responder las reseñas que te dejaron';
  end if;

  insert into public.respuestas_resenas (calificacion_id, autor_id, texto)
  values (p_calificacion, (select auth.uid()), v_texto)
  on conflict (calificacion_id) do update
     set texto = excluded.texto;
end;
$$;

revoke execute on function public.responder_resena(uuid, text) from public, anon;
grant execute on function public.responder_resena(uuid, text) to authenticated;

-- c1 · La vista suma la respuesta al final ("create or replace view" solo
-- permite agregar columnas al final). La regla de visibilidad no cambia.
create or replace view public.resenas_publicas as
select c.id,
       c.solicitud_id,
       c.autor_id,
       a.nombre as autor_nombre,
       c.destinatario_id,
       c.estrellas,
       c.comentario,
       c.created_at,
       rr.texto as respuesta,
       rr.updated_at as respuesta_en
  from public.calificaciones c
  join public.perfiles a on a.id = c.autor_id
  left join public.respuestas_resenas rr on rr.calificacion_id = c.id
 where c.created_at <= now() - interval '7 days'
    or exists (
      select 1 from public.calificaciones otra
       where otra.solicitud_id = c.solicitud_id
         and otra.autor_id = c.destinatario_id
    );
