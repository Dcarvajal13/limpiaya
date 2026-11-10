/// HU-25 c2 · Cómo ordenar el resultado de "Buscar trabajadoras".
enum OrdenTrabajadoras {
  calificacion('Mejor calificación'),
  servicios('Más servicios completados');

  const OrdenTrabajadoras(this.etiqueta);

  final String etiqueta;
}
