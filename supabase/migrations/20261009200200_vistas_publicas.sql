-- =============================================================================
-- LimpiaYa · Migración 3: vistas públicas
-- Lo que un usuario puede ver de OTROS usuarios, sin datos privados
-- (teléfono, correo, dirección exacta). La app lee estas vistas igual que
-- una tabla:  supabase.from('trabajadoras_publicas').select()
--
-- Nota: estas vistas corren con los permisos de su dueño a propósito, para
-- mostrar solo las columnas seguras. Por eso el panel de Supabase puede
-- avisar "Security Definer View": es intencional. Cada vista filtra por
-- auth.uid() cuando hace falta y solo la pueden leer usuarios con sesión.
-- =============================================================================

-- Nombre y foto de cualquier usuario (para postulantes, chat, reseñas)
create view public.perfiles_publicos as
select p.id, p.rol, p.nombre, p.foto_path
  from public.perfiles p;

-- Reseñas visibles (HU-29 c4): se muestran cuando ambas partes calificaron
-- ese servicio o cuando pasaron 7 días.
create view public.resenas_publicas as
select c.id,
       c.solicitud_id,
       c.autor_id,
       a.nombre as autor_nombre,
       c.destinatario_id,
       c.estrellas,
       c.comentario,
       c.created_at
  from public.calificaciones c
  join public.perfiles a on a.id = c.autor_id
 where c.created_at <= now() - interval '7 days'
    or exists (
      select 1 from public.calificaciones otra
       where otra.solicitud_id = c.solicitud_id
         and otra.autor_id = c.destinatario_id
    );

-- Promedio y servicios completados de cada usuario (HU-06, HU-14)
create view public.reputacion as
select p.id as usuario_id,
       (select round(avg(r.estrellas), 1)
          from public.resenas_publicas r
         where r.destinatario_id = p.id) as promedio,
       (select count(*)
          from public.resenas_publicas r
         where r.destinatario_id = p.id) as total_resenas,
       (select count(*)
          from public.solicitudes s
         where s.estado = 'completada'
           and p.id in (s.cliente_id, s.trabajadora_id)) as servicios_completados
  from public.perfiles p;

-- Perfil público de una trabajadora (HU-06): sin teléfono ni correo.
create view public.trabajadoras_publicas as
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
       r.servicios_completados
  from public.perfiles p
  join public.trabajadoras t on t.id = p.id
  join public.reputacion r on r.usuario_id = p.id;

-- Solicitudes SIN dirección exacta (HU-11, HU-13, HU-45).
-- Muestra: las Publicadas y futuras de mis zonas, las que yo publiqué,
-- las que tengo asignadas y aquellas a las que me postulé.
create view public.solicitudes_publicas as
select s.id,
       s.cliente_id,
       s.trabajadora_id,
       s.estado,
       s.tipo,
       s.zona_id,
       z.nombre as zona,
       s.inicio,
       s.horas_estimadas,
       s.fin,
       s.pago_ofrecido,
       s.metodo_pago,
       s.habitaciones,
       s.banos,
       s.tiene_mascotas,
       s.productos_por,
       s.notas,
       s.created_at,
       (select count(*)
          from public.postulaciones po
         where po.solicitud_id = s.id
           and po.estado in ('pendiente', 'aceptada')) as num_postulantes,
       exists (
         select 1 from public.postulaciones po
          where po.solicitud_id = s.id
            and po.trabajadora_id = (select auth.uid())
            and po.estado in ('pendiente', 'aceptada')) as ya_me_postule
  from public.solicitudes s
  join public.zonas z on z.id = s.zona_id
 where (
         s.estado = 'publicada'
         and s.inicio > now()
         and exists (
           select 1 from public.trabajadora_zonas tz
            where tz.trabajadora_id = (select auth.uid())
              and tz.zona_id = s.zona_id)
       )
    or s.cliente_id = (select auth.uid())
    or s.trabajadora_id = (select auth.uid())
    or exists (
         select 1 from public.postulaciones po
          where po.solicitud_id = s.id
            and po.trabajadora_id = (select auth.uid()))
    or (select public.es_admin());

-- Solo usuarios con sesión pueden leer las vistas
revoke all on public.perfiles_publicos, public.resenas_publicas, public.reputacion,
              public.trabajadoras_publicas, public.solicitudes_publicas
  from public, anon, authenticated;

grant select on public.perfiles_publicos, public.resenas_publicas, public.reputacion,
                public.trabajadoras_publicas, public.solicitudes_publicas
  to authenticated;
