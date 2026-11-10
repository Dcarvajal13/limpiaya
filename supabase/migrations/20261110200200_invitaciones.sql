-- ---------------------------------------------------------------------------
-- HU-25 · Buscar trabajadoras e invitarlas a una solicitud
--
-- Buscar y ordenar (c1, c2, c4): la app lee la vista trabajadoras_publicas,
-- que ahora suma zona_ids (los ids de sus zonas) para filtrar por zona sin
-- comparar nombres. Lo de invitar (c3):
-- - El cliente invita a una trabajadora a una de sus solicitudes Publicadas.
-- - La trabajadora ve esa solicitud marcada como "Te invitaron" (la vista
--   solicitudes_publicas suma la columna me_invitaron, al final).
-- Solo se invita a quien trabaja en la zona de la solicitud: así puede
-- postularse (puede_postularse exige la zona) y la ve en su lista de
-- trabajos sin cambiar nada más.
-- ---------------------------------------------------------------------------
create table public.invitaciones (
  solicitud_id   uuid not null references public.solicitudes (id) on delete cascade,
  trabajadora_id uuid not null references public.trabajadoras (id) on delete cascade,
  created_at     timestamptz not null default now(),
  primary key (solicitud_id, trabajadora_id)
);

create index invitaciones_trabajadora_idx on public.invitaciones (trabajadora_id);

comment on table public.invitaciones is
  'HU-25: el cliente invita a una trabajadora a postularse a su solicitud.';

alter table public.invitaciones enable row level security;

revoke all on public.invitaciones from public, anon, authenticated;
grant select on public.invitaciones to authenticated;

create policy "invitaciones: leer las mías" on public.invitaciones
  for select to authenticated
  using (
    trabajadora_id = (select auth.uid())
    or exists (
      select 1 from public.solicitudes s
       where s.id = solicitud_id and s.cliente_id = (select auth.uid()))
    or (select public.es_admin())
  );

create or replace function public.invitar_trabajadora(
  p_solicitud   uuid,
  p_trabajadora uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_solicitud public.solicitudes%rowtype;
begin
  select *
    into v_solicitud
    from public.solicitudes
   where id = p_solicitud
     and cliente_id = (select auth.uid())
     for update;

  if not found then
    raise exception 'No encontramos esa solicitud';
  end if;

  if v_solicitud.estado <> 'publicada' or v_solicitud.inicio <= now() then
    raise exception 'Solo puedes invitar a una solicitud publicada';
  end if;

  if not exists (
    select 1 from public.trabajadoras t
     where t.id = p_trabajadora
       and t.verificacion = 'aprobada'
  ) then
    raise exception 'No encontramos a esa trabajadora';
  end if;

  if not exists (
    select 1 from public.trabajadora_zonas tz
     where tz.trabajadora_id = p_trabajadora
       and tz.zona_id = v_solicitud.zona_id
  ) then
    raise exception 'Ella no trabaja en la zona de esta solicitud';
  end if;

  if exists (
    select 1 from public.postulaciones po
     where po.solicitud_id = p_solicitud
       and po.trabajadora_id = p_trabajadora
       and po.estado in ('pendiente', 'aceptada')
  ) then
    raise exception 'Ella ya se postuló a esta solicitud';
  end if;

  if exists (
    select 1 from public.invitaciones i
     where i.solicitud_id = p_solicitud
       and i.trabajadora_id = p_trabajadora
  ) then
    raise exception 'Ya la invitaste a esta solicitud';
  end if;

  insert into public.invitaciones (solicitud_id, trabajadora_id)
  values (p_solicitud, p_trabajadora);
end;
$$;

revoke execute on function public.invitar_trabajadora(uuid, uuid) from public, anon;
grant execute on function public.invitar_trabajadora(uuid, uuid) to authenticated;

-- c1 · Ids de las zonas de cada trabajadora, al final de la vista (el resto
-- queda igual que en la migración de HU-61).
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
       n.destacada,
       coalesce((select array_agg(tz.zona_id order by tz.zona_id)
                   from public.trabajadora_zonas tz
                  where tz.trabajadora_id = p.id), '{}') as zona_ids
  from public.perfiles p
  join public.trabajadoras t on t.id = p.id
  join public.reputacion r on r.usuario_id = p.id
  join public.nivel_trabajadoras n on n.trabajadora_id = p.id;

-- c3 · La trabajadora ve la marca "Te invitaron". La columna va al final
-- ("create or replace view" solo permite agregar al final); el resto queda
-- igual que en la migración de HU-28.
create or replace view public.solicitudes_publicas as
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
            and po.estado in ('pendiente', 'aceptada')) as ya_me_postule,
       s.motivo_cancelacion,
       s.cancelada_por,
       exists (
         select 1 from public.invitaciones i
          where i.solicitud_id = s.id
            and i.trabajadora_id = (select auth.uid())) as me_invitaron
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
