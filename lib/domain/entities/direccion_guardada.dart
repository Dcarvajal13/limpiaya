/// Una dirección que el cliente guardó con un nombre ("Casa", "Oficina"…)
/// para elegirla al publicar una solicitud sin volver a escribirla.
///
/// Es privada: solo la ve su dueño. Las trabajadoras siguen viendo solo la
/// zona de cada solicitud.
class DireccionGuardada {
  const DireccionGuardada({
    required this.id,
    required this.nombre,
    required this.zonaId,
    required this.direccion,
    this.zona,
    this.puntoReferencia,
  });

  final String id;

  /// Cómo la llama el cliente: "Casa", "Casa de mi mamá"…
  final String nombre;

  final int zonaId;

  /// Nombre de la urbanización ("Los Palos Grandes"), si se pudo leer.
  final String? zona;

  final String direccion;
  final String? puntoReferencia;
}
