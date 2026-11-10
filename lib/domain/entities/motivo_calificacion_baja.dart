/// HU-30 c2 · Motivo obligatorio cuando la trabajadora pone 1 o 2 estrellas
/// (enum `motivo_calificacion_baja` en Supabase).
enum MotivoCalificacionBaja {
  pagoIncompleto('pago_incompleto', 'Pago incompleto'),
  trato('trato', 'Trato'),
  condicionesDistintas(
    'condiciones_distintas',
    'Condiciones distintas a lo publicado',
  ),
  otro('otro', 'Otro');

  const MotivoCalificacionBaja(this.valorDb, this.etiqueta);

  /// Valor exacto en la base de datos Postgres.
  final String valorDb;

  /// Texto mostrado al usuario.
  final String etiqueta;
}
