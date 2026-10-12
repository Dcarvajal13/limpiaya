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
    this.verificacion,
  });

  final String id;
  final RolUsuario rol;
  final String nombre;

  /// Si ya llenó los datos que su rol necesita (zona y dirección para el
  /// cliente; zonas y servicios para la trabajadora). Lo usan HU-04 y HU-05.
  final bool perfilCompleto;

  /// Ruta de la foto en el bucket `avatars`, o null si no tiene.
  final String? fotoPath;

  /// Solo para trabajadoras: pendiente, en_revision, aprobada o rechazada.
  final String? verificacion;
}
