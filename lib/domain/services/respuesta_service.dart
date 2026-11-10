/// Reglas de HU-31 · Responder a una reseña.
///
/// Vive en el dominio y no conoce Supabase ni Flutter.
abstract final class RespuestaService {
  /// c3 · Largo máximo (lo valida también la base).
  static const maxCaracteres = 300;

  /// c3 · Se pasó del límite.
  static const mensajeLimite = 'La respuesta puede tener hasta 300 caracteres';

  /// Intentó publicar sin escribir nada.
  static const mensajeVacia = 'Escribe tu respuesta';

  /// La reseña no es suya o todavía no se muestra.
  static const mensajeNoPermitida =
      'Solo puedes responder las reseñas que te dejaron';

  /// Cualquier otro fallo (sin red, base de datos).
  static const mensajeError =
      'No pudimos publicar tu respuesta. Intenta de nuevo.';

  /// c1 · Confirmación al publicar.
  static const mensajePublicada = 'Tu respuesta quedó publicada.';

  /// c2 · Confirmación al editar.
  static const mensajeEditada = 'Tu respuesta quedó actualizada.';

  /// null si se puede publicar, o el mensaje de error.
  static String? validar(String? texto) {
    final limpio = texto?.trim() ?? '';
    if (limpio.isEmpty) return mensajeVacia;
    if (limpio.length > maxCaracteres) return mensajeLimite;
    return null;
  }
}
