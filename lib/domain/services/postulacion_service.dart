/// Reglas de negocio de HU-12 · Postularme a una solicitud.
///
/// Vive en el dominio y no conoce Supabase, igual que `filtro_solicitudes.dart`:
/// así las reglas se prueban solas, sin red ni base de datos.
abstract final class PostulacionService {
  /// c2 · Ya tengo una postulación viva para esa solicitud.
  static const mensajeYaPostulada = 'Ya te postulaste a esta solicitud';

  /// c3 · Esa fecha y hora se cruzan con un servicio que ya tengo asignado.
  static const mensajeSolape = 'Ya tienes un servicio en ese horario';

  /// c4 · Todavía no aprobó su verificación de identidad (HU-21).
  static const mensajeVerificacion = 'Verifica tu identidad para postularte';

  /// La sesión venció mientras se enviaba la postulación.
  static const mensajeSesion = 'Tu sesión expiró. Inicia sesión de nuevo.';

  /// Cualquier otro fallo (sin red, RLS, base de datos).
  static const mensajeError =
      'No pudimos enviar tu postulación. Intenta de nuevo.';

  /// Mensaje de confirmación al enviar la postulación.
  static const mensajeEnviada =
      '¡Postulación enviada! El cliente ya puede verte en su lista.';

  /// c4 · Su identidad está aprobada (`verificaciones.estado`).
  static bool identidadAprobada(String? verificacion) =>
      verificacion == 'aprobada';

  /// c3 · ¿El rango [inicio]–[fin] se cruza con alguno de [servicios]?
  ///
  /// Los extremos que apenas se tocan no cuentan: un servicio que termina a
  /// las 12:00 y otro que empieza a las 12:00 no se solapan.
  static bool seCruza({
    required DateTime inicio,
    required DateTime fin,
    required Iterable<(DateTime, DateTime)> servicios,
  }) {
    for (final (otroInicio, otroFin) in servicios) {
      if (inicio.isBefore(otroFin) && fin.isAfter(otroInicio)) return true;
    }
    return false;
  }
}
