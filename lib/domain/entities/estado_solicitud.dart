/// Estado de una solicitud / servicio (enum `estado_solicitud` en Supabase).
enum EstadoSolicitud {
  publicada('publicada', 'Publicada'),
  asignada('asignada', 'Asignada'),
  completada('completada', 'Completada'),
  cancelada('cancelada', 'Cancelada');

  const EstadoSolicitud(this.valorDb, this.etiqueta);

  /// Valor exacto en la base de datos Postgres.
  final String valorDb;

  /// Texto mostrado al usuario.
  final String etiqueta;

  static EstadoSolicitud desdeDb(String valor) =>
      EstadoSolicitud.values.firstWhere(
        (e) => e.valorDb == valor,
        orElse: () => EstadoSolicitud.publicada,
      );
}
