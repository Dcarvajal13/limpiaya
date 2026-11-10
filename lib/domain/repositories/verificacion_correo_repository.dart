/// HU-40 · Contrato para verificar el correo: QUÉ se puede pedir, sin decir
/// CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_verificacion_correo_repository.dart.
abstract interface class VerificacionCorreoRepository {
  /// c2 · Vuelve a enviar el enlace de confirmación a [email].
  Future<void> reenviar(String email);
}
