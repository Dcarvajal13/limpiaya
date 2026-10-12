import '../entities/rol_usuario.dart';
import '../entities/usuario.dart';

/// Contrato de autenticación: QUÉ se puede hacer, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_auth_repository.dart.
/// Las pantallas y providers solo conocen esta clase.
abstract interface class AuthRepository {
  /// Usuario con sesión activa, o null si nadie ha iniciado sesión.
  Usuario? get usuarioActual;

  /// Avisa cada vez que alguien inicia o cierra sesión.
  Stream<Usuario?> cambiosDeSesion();

  /// HU-01 · Registrarme eligiendo mi rol.
  Future<void> registrarse({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario rol,
  });

  /// HU-02A / HU-02B · Iniciar sesión.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  });

  /// HU-03 · Cerrar sesión.
  Future<void> cerrarSesion();
}
