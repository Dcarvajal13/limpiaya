/// Lo que una persona puede hacer sobre su propia cuenta.
///
/// - HU-39 · Cambiar la contraseña desde la cuenta.
/// - HU-42 · Desactivar la cuenta.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_cuenta_repository.dart.
abstract interface class CuentaRepository {
  /// Cambia la contraseña. Antes comprueba la actual: si no coincide, lanza
  /// AppException con el mensaje que debe ver la persona y no cambia nada.
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  });

  /// Desactiva la cuenta. Si hay servicios asignados sin completar, lanza
  /// AppException explicando que primero debe completarlos o cancelarlos.
  Future<void> desactivar();
}
