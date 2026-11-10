/// Zona de Caracas donde se ofrece el servicio (tabla `zonas`).
///
/// Corrección de la revisión: cada urbanización sabe su municipio y su
/// parroquia, para elegirla en orden Municipio → Parroquia → Urbanización.
/// Los dos campos son opcionales para no romper las consultas que solo
/// necesitan el nombre (por ejemplo, el detalle de una solicitud).
class Zona {
  const Zona({
    required this.id,
    required this.nombre,
    this.municipio = '',
    this.parroquia = '',
  });

  final int id;

  /// Nombre de la urbanización, por ejemplo "Los Palos Grandes".
  final String nombre;

  /// Municipio, por ejemplo "Chacao".
  final String municipio;

  /// Parroquia, por ejemplo "Chacao" o "El Recreo".
  final String parroquia;

  /// Lee una fila de la tabla `zonas` (o del `select` anidado de otra tabla).
  factory Zona.desdeFila(Map<dynamic, dynamic> fila) => Zona(
        id: fila['id'] as int,
        nombre: fila['nombre'] as String,
        municipio: fila['municipio'] as String? ?? '',
        parroquia: fila['parroquia'] as String? ?? '',
      );
}
