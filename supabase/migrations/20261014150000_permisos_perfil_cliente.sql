-- =============================================================================
-- LimpiaYa · Permisos del perfil del cliente (HU-05)
-- =============================================================================
-- Guardar el perfil del cliente fallaba con:
--   "permission denied for table clientes"
--
-- Causa: el upsert de PostgREST genera
--   INSERT ... ON CONFLICT (id) DO UPDATE SET id = excluded.id, ...
-- y el rol `authenticated` tenía UPDATE solo sobre zona_id, direccion y
-- punto_referencia, NO sobre `id`. PostgreSQL exige privilegio UPDATE sobre
-- todas las columnas del SET, incluida la clave del ON CONFLICT.
--
-- Los GRANT son idempotentes: volver a ejecutarlos no rompe nada.
-- Aplicar con:  supabase db push
-- =============================================================================

grant update (id, zona_id, direccion, punto_referencia) on public.clientes to authenticated;
grant insert (id, zona_id, direccion, punto_referencia) on public.clientes to authenticated;
