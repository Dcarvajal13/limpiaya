-- ---------------------------------------------------------------------------
-- HU-61 · Subir de nivel como trabajadora (insignia "Destacada")
--
-- - c1: con 10 servicios completados o más, promedio de 4,5 o más y ninguna
--   cancelación tardía (HU-28) en los últimos 30 días, obtiene la insignia.
-- - c2: con la insignia aparece primero entre las postulantes (la app ordena
--   con la columna destacada).
-- - c3: si su promedio baja de 4,5 la pierde. No hace falta un proceso que
--   "recalcule": es una vista, así que se calcula cada vez que se consulta.
--
-- El promedio es el de la vista reputacion: solo cuenta las reseñas ya
-- visibles (HU-29 c4).
--
-- nivel_trabajadoras es interna (la app no la lee directo): el número de
-- cancelaciones tardías es privado. Los clientes solo ven la columna
-- destacada en trabajadoras_publicas, y cada trabajadora ve su propio
-- progreso en mi_nivel.
-- ---------------------------------------------------------------------------
create view public.nivel_trabajadoras as
select t.id as trabajadora_id,
       r.servicios_completados,
       r.promedio,
       c.cancelaciones_tardias,
       (r.servicios_completados >= 10
        and coalesce(r.promedio, 0) >= 4.5
        and c.cancelaciones_tardias = 0) as destacada
  from public.trabajadoras t
  join public.reputacion r on r.usuario_id = t.id
 cross join lateral (
       select count(*) as cancelaciones_tardias
         from public.solicitudes s
        where s.cancelada_por = t.id
          and s.cancelacion_tardia
          and s.cancelada_en > now() - interval '30 days'
       ) c;

-- Perfil público de una trabajadora (HU-06) + la insignia, al final.
create or replace view public.trabajadoras_publicas as
select p.id,
       p.nombre,
       p.foto_path,
       t.experiencia_anios,
       t.tarifa_referencia,
       t.descripcion,
       t.verificacion = 'aprobada' as verificada,
       coalesce((select array_agg(z.nombre order by z.nombre)
                   from public.trabajadora_zonas tz
                   join public.zonas z on z.id = tz.zona_id
                  where tz.trabajadora_id = p.id), '{}') as zonas,
       coalesce((select array_agg(sv.tipo order by sv.tipo)
                   from public.trabajadora_servicios sv
                  where sv.trabajadora_id = p.id), '{}') as servicios,
       r.promedio,
       r.total_resenas,
       r.servicios_completados,
       n.destacada
  from public.perfiles p
  join public.trabajadoras t on t.id = p.id
  join public.reputacion r on r.usuario_id = p.id
  join public.nivel_trabajadoras n on n.trabajadora_id = p.id;

-- Mi propio nivel y lo que me falta (pantalla "Mi reputación").
create view public.mi_nivel as
select n.*
  from public.nivel_trabajadoras n
 where n.trabajadora_id = (select auth.uid());

revoke all on public.nivel_trabajadoras, public.mi_nivel
  from public, anon, authenticated;
grant select on public.mi_nivel to authenticated;
