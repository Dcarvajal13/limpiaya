/// Un mensaje del chat de un servicio (HU-38).
///
/// Sale de la tabla `mensajes`: el autor, el texto y cuándo se envió. Nada
/// de Supabase aquí: la conversión está en data/models/mensaje_model.dart.
class Mensaje {
  const Mensaje({
    required this.id,
    required this.solicitudId,
    required this.autorId,
    required this.contenido,
    required this.enviadoEn,
    this.leidoEn,
  });

  final int id;
  final String solicitudId;

  /// Quién lo escribió. Se compara con la sesión para saber de qué lado va.
  final String autorId;

  final String contenido;
  final DateTime enviadoEn;

  /// Cuándo lo leyó la otra parte; null mientras no lo haya abierto.
  final DateTime? leidoEn;

  bool get leido => leidoEn != null;

  bool esMio(String usuarioId) => autorId == usuarioId;
}
