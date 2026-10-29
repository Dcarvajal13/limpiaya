/// Estados de la verificación de identidad (enum estado_verificacion).
enum EstadoVerificacion {
  pendiente,
  enRevision,
  aprobada,
  rechazada;

  /// 'en_revision' → EstadoVerificacion.enRevision. Desconocido → pendiente.
  static EstadoVerificacion desdeTexto(String? texto) => switch (texto) {
        'en_revision' => EstadoVerificacion.enRevision,
        'aprobada' => EstadoVerificacion.aprobada,
        'rechazada' => EstadoVerificacion.rechazada,
        _ => EstadoVerificacion.pendiente,
      };
}

/// HU-21 · La última verificación que envió la trabajadora con sesión.
class MiVerificacion {
  const MiVerificacion({
    required this.estado,
    required this.enviada,
    this.motivoRechazo,
  });

  final EstadoVerificacion estado;
  final DateTime enviada;

  /// Lo que escribió el administrador al rechazarla (HU-21 c3).
  final String? motivoRechazo;
}
