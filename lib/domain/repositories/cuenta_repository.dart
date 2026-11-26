import '../entities/datos_personales.dart';

/// Lo que una persona puede hacer sobre su propia cuenta.
///
/// - HU-41 · Editar nombre y teléfono.
/// - HU-39 · Cambiar la contraseña desde la cuenta.
/// - HU-42 · Desactivar la cuenta.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_cuenta_repository.dart.
abstract interface class CuentaRepository {
  /// HU-41 · Nombre y teléfono actuales del perfil.
  Future<DatosPersonales> datosPersonales();

  /// HU-41 · Guarda nombre y teléfono. Lanza AppException si no se pudo.
  Future<void> actualizarDatos({
    required String nombre,
    required String telefono,
  });

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
