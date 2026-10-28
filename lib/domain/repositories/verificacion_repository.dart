import '../entities/verificacion_pendiente.dart';

/// Contrato de verificaciones de identidad: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_verificacion_repository.dart.
abstract interface class VerificacionRepository {
  /// HU-33 c1 · Verificaciones en revisión, de la más antigua a la más
  /// reciente, con las fotos y los datos de la cuenta.
  Future<List<VerificacionPendiente>> pendientes();

  /// HU-33 c2 · Aprueba la verificación. La base de datos marca a la
  /// trabajadora como verificada (trigger sincronizar_verificacion).
  Future<void> aprobar(String id);

  /// HU-33 c3 · Rechaza la verificación con el motivo que verá la trabajadora.
  Future<void> rechazar(String id, String motivo);
}
