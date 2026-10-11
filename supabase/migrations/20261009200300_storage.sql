-- =============================================================================
-- LimpiaYa · Migración 4: almacenamiento de fotos (HD-02 criterio 2)
--
-- Buckets:
--   avatars         Fotos de perfil. Públicas para mostrarlas con una URL.
--   verificaciones  Cédula y selfie (HU-21). PRIVADAS: solo la dueña y el admin.
--
-- Cada archivo va dentro de una carpeta con el id del usuario:
--   avatars/<uid>/perfil.jpg
--   verificaciones/<uid>/cedula-<fecha>.jpg
-- Así cada quien solo puede subir y borrar dentro de su carpeta.
-- Límite: 5 MB, solo JPG o PNG (HU-04 c4).
-- =============================================================================

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png']),
  ('verificaciones', 'verificaciones', false, 5242880, array['image/jpeg', 'image/png'])
on conflict (id) do nothing;

-- avatars ---------------------------------------------------------------------
create policy "avatars: ver con sesión" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars');

create policy "avatars: subir a mi carpeta" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars: reemplazar en mi carpeta" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "avatars: borrar de mi carpeta" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- verificaciones --------------------------------------------------------------
create policy "verificaciones: subir a mi carpeta" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'verificaciones'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "verificaciones: ver las mías o si soy admin" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'verificaciones'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select public.es_admin())
    )
  );
