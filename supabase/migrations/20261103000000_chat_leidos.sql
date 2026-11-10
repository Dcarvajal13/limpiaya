-- ---------------------------------------------------------------------------
-- Sprint 3 · Fase 0: lo que faltaba para el chat (HU-38)
--
-- El resto ya existe desde la migración de seguridad: las políticas de
-- `mensajes` (leer los de mis servicios, escribir si el chat está abierto),
-- las de `calificaciones` y la publicación de Realtime.
--
-- Lo único que no había forma de guardar es qué mensajes ya leyó la otra
-- parte, y HU-38 criterio 3 pide un aviso de mensajes sin leer en "Mensajes".
-- ---------------------------------------------------------------------------

alter table public.mensajes
  add column if not exists leido_en timestamptz;

-- Los no leídos se buscan por servicio: solo interesan los que están a null.
create index if not exists mensajes_no_leidos_idx
  on public.mensajes (solicitud_id)
  where leido_en is null;

-- El autor no puede marcar sus propios mensajes: solo la otra parte del
-- servicio, y solo mientras sea participante de esa solicitud.
grant update (leido_en) on public.mensajes to authenticated;

create policy "mensajes: marcar como leídos los de mi servicio" on public.mensajes
  for update to authenticated
  using (
    public.es_participante(solicitud_id)
    and autor_id <> (select auth.uid())
  )
  with check (
    public.es_participante(solicitud_id)
    and autor_id <> (select auth.uid())
  );
