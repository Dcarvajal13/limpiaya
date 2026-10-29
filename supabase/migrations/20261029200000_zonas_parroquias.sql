-- ===========================================================================
-- Corrección de la revisión · Zonas por Municipio → Parroquia → Urbanización
-- ===========================================================================
-- El profesor pidió que las zonas no salgan todas juntas, sino ordenadas
-- como se ubica la gente en Caracas. La tabla ya tenía el municipio; aquí se
-- agrega la parroquia de cada una de las 40 urbanizaciones.
--
-- Revisar antes de la entrega (no se encontró una fuente oficial que lo
-- confirme; se usó la división más citada):
--   * Los Chaguaramos y Santa Mónica → San Pedro
--   * La Florida → El Recreo
--   * Centro → Catedral
--   * La Urbina, Terrazas del Ávila y Macaracuay → Petare
-- Si alguna está mal, basta con un update de esa fila.
-- ===========================================================================

alter table public.zonas add column if not exists parroquia text;

update public.zonas set parroquia = case
  -- Baruta: El Cafetal es su propia parroquia; el resto de estas
  -- urbanizaciones está en Nuestra Señora del Rosario (Baruta).
  when municipio = 'Baruta' and nombre = 'El Cafetal' then 'El Cafetal'
  when municipio = 'Baruta' then 'Nuestra Señora del Rosario'

  -- Chacao y El Hatillo tienen una sola parroquia cada uno.
  when municipio = 'Chacao' then 'Chacao'
  when municipio = 'El Hatillo' then 'Santa Rosalía de Palermo'

  -- Sucre
  when municipio = 'Sucre' and nombre in (
    'Los Dos Caminos', 'Boleíta', 'Los Ruices', 'Santa Eduvigis', 'Sebucán'
  ) then 'Leoncio Martínez'
  when municipio = 'Sucre' then 'Petare'

  -- Libertador
  when nombre in ('Sabana Grande', 'La Florida') then 'El Recreo'
  when nombre in ('Los Chaguaramos', 'Santa Mónica') then 'San Pedro'
  when nombre = 'El Paraíso' then 'El Paraíso'
  when nombre = 'La Candelaria' then 'La Candelaria'
  when nombre = 'San Bernardino' then 'San Bernardino'
  when nombre = 'Montalbán' then 'La Vega'
  when nombre = 'El Valle' then 'El Valle'
  when nombre = 'Centro' then 'Catedral'
end
where parroquia is null;

-- Una zona nueva sin parroquia quedaría suelta en el selector: se exige.
-- (Si el equipo agregó zonas propias, este paso avisa cuáles faltan.)
do $$
declare
  v_faltan text;
begin
  select string_agg(nombre || ' (' || municipio || ')', ', ')
    into v_faltan
    from public.zonas
   where parroquia is null;
  if v_faltan is not null then
    raise exception 'Estas zonas no tienen parroquia: %. Agrégala con un update y vuelve a correr la migración.', v_faltan;
  end if;
end $$;

alter table public.zonas alter column parroquia set not null;

comment on column public.zonas.parroquia is
  'Parroquia de la urbanización. Las pantallas eligen Municipio → Parroquia → Urbanización.';

-- La columna nueva queda incluida en el grant select de la tabla
-- (migración de seguridad), así que no hace falta otro permiso.
