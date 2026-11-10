/// Contrato de servicios: lo que pasa con una solicitud desde que el cliente
/// elige a una trabajadora. QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_servicio_repository.dart. Cada cambio de estado
/// es una función de Postgres, porque nadie puede escribir la columna
/// `estado` directamente (HD-04).
abstract interface class ServicioRepository {
  /// HU-15 · El cliente elige a una postulante: la solicitud pasa a Asignada,
  /// esa postulación a Aceptada y las demás pendientes a No seleccionada.
  ///
  /// Lanza `AppException` con el mensaje que debe ver el cliente si la
  /// solicitud ya no está Publicada, la postulante se retiró o ya tiene otro
  /// servicio en ese horario.
  Future<void> elegir(String postulacionId);
}
