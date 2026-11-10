/// Una calificación que dejó quien inició sesión sobre un servicio
/// Completado (HU-29 cliente → trabajadora, HU-30 trabajadora → cliente).
class Calificacion {
  const Calificacion({
    required this.solicitudId,
    required this.estrellas,
    this.comentario,
    this.fecha,
  });

  final String solicitudId;

  /// De 1 a 5.
  final int estrellas;
  final String? comentario;

  /// Cuándo se envió, en la hora local de quien la mira.
  final DateTime? fecha;
}
