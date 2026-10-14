-- =============================================================================
-- LimpiaYa · Permisos del perfil del cliente (HU-05)
-- =============================================================================
-- La tabla `clientes` ya tenía el INSERT en la migración original, pero el
-- UPDATE no quedó aplicado en la base: guardar el perfil del cliente
-- (zona, dirección y punto de referencia) fallaba con
-- "permission denied for table clientes".
--
-- Los GRANT son idempotentes: volver a ejecutarlos no rompe nada.
-- Aplicar con:  supabase db push
-- =============================================================================

grant update (zona_id, direccion, punto_referencia) on public.clientes to authenticated;
grant insert (id, zona_id, direccion, punto_referencia) on public.clientes to authenticated;
