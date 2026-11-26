import 'rol_usuario.dart';

/// Lo que la app necesita saber de quien inició sesión: su rol y su nombre.
///
/// Viene de la función `mi_sesion()` de la base de datos (HD-03).
/// Es una entidad del dominio: no sabe nada de Supabase.
class Sesion {
  const Sesion({
    required this.id,
    required this.rol,
    required this.nombre,
    required this.perfilCompleto,
    this.fotoPath,
    this.fotoUrl,
    this.verificacion,
    this.activo = true,
    this.suspendido = false,
    this.motivoSuspension,
    this.avisosCorreo = true,
  });

  final String id;
  final RolUsuario rol;
  final String nombre;

  /// Si ya llenó los datos que su rol necesita (zona y dirección para el
  /// cliente; zonas y servicios para la trabajadora). Lo usan HU-04 y HU-05.
  final bool perfilCompleto;

  /// Ruta de la foto en el bucket `avatars`, o null si no tiene.
  final String? fotoPath;

  /// Dirección pública de la foto (para mostrarla), o null si no tiene.
  final String? fotoUrl;

  /// Verificación de identidad (clientes y trabajadoras): pendiente,
  /// en_revision, aprobada o rechazada. Null para el admin.
  final String? verificacion;

  /// HU-42 · false cuando la persona desactivó su cuenta. Una cuenta
  /// desactivada no puede iniciar sesión.
  final bool activo;

  /// HU-34 · true cuando administración suspendió la cuenta.
  final bool suspendido;
  final String? motivoSuspension;

  /// HU-49 · Si recibe avisos por correo electrónico.
  final bool avisosCorreo;
}
