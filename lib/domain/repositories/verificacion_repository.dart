import '../entities/archivo_foto.dart';
import '../entities/mi_verificacion.dart';
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

  /// HU-21 · Última verificación de la trabajadora con sesión, o null si
  /// nunca envió documentos.
  Future<MiVerificacion?> miUltima();

  /// HU-21 c1 · Sube la foto de la cédula y la selfie al bucket privado y
  /// crea la verificación "En revisión".
  Future<void> enviar({required ArchivoFoto cedula, required ArchivoFoto selfie});
}
