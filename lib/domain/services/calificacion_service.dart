/// Reglas de negocio de HU-29 · Calificar a la trabajadora.
///
/// Vive en el dominio y no conoce Supabase, igual que `ServicioService`.
abstract final class CalificacionService {
  /// c2 · Intentó enviar sin elegir estrellas.
  static const mensajeEligeEstrellas = 'Elige de 1 a 5 estrellas';

  /// c3 · Ya había calificado ese servicio.
  static const mensajeYaCalificaste = 'Ya calificaste este servicio';

  /// La base solo deja calificar un servicio Completado.
  static const mensajeNoCompletado =
      'Solo puedes calificar un servicio completado';

  /// Cualquier otro fallo (sin red, base de datos).
  static const mensajeError =
      'No pudimos enviar tu calificación. Intenta de nuevo.';

  /// Confirmación al enviar (c1).
  static const mensajeEnviada = '¡Gracias! Tu calificación quedó guardada.';

  /// c4 · Mientras la otra parte no califique, la reseña no se muestra.
  static const mensajeOculta =
      'Tu reseña se publicará cuando la trabajadora también califique o '
      'pasen 7 días.';

  /// Largo máximo del comentario (lo valida también la base).
  static const maxComentario = 500;

  /// c2 · ¿Las estrellas son válidas? null si no eligió ninguna.
  static bool estrellasValidas(int? estrellas) =>
      estrellas != null && estrellas >= 1 && estrellas <= 5;

  /// El comentario se guarda sin espacios sobrantes; vacío = sin comentario.
  static String? limpiarComentario(String? comentario) {
    final texto = comentario?.trim();
    return (texto == null || texto.isEmpty) ? null : texto;
  }
}
