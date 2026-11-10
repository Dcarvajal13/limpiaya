import '../entities/rol_usuario.dart';
import '../entities/sesion.dart';
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

  /// Rol, nombre y estado del perfil de quien inició sesión
  /// (HU-02A / HU-02B). Devuelve null si no hay sesión o no tiene perfil.
  Future<Sesion?> obtenerSesion();

  /// HU-03 · Cerrar sesión.
  Future<void> cerrarSesion();

  /// HU-19 · Recuperar contraseña (taller UX, H3 y H9, severidad 3).
  /// Envía al correo un enlace que abre la app en "Nueva contraseña".
  /// No dice si el correo tiene cuenta, para no revelarlo.
  Future<void> enviarRecuperacion(String email);

  /// HU-19 · Cambia la contraseña de quien entró con el enlace de
  /// recuperación.
  Future<void> cambiarPassword(String nueva);
}
