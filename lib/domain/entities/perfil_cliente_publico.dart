import 'perfil_publico.dart';

/// HU-46 · Lo que una trabajadora puede ver de un cliente antes de
/// postularse: nombre, foto, reputación y las reseñas que le dejaron otras
/// trabajadoras.
///
/// Sale de las vistas `perfiles_publicos`, `reputacion` y `resenas_publicas`:
/// **nunca** trae teléfono, correo ni dirección.
class PerfilClientePublico {
  const PerfilClientePublico({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    this.promedio,
    this.totalResenas = 0,
    this.serviciosCompletados = 0,
    this.resenas = const [],
  });

  final String id;
  final String nombre;
  final String? fotoUrl;

  /// Promedio de 1 a 5, o null si nadie lo ha calificado todavía.
  final double? promedio;
  final int totalResenas;

  /// Servicios Completados en LimpiaYa (como cliente).
  final int serviciosCompletados;

  /// Reseñas visibles que le dejaron las trabajadoras (HU-30, HU-29 c4).
  final List<ResenaPublica> resenas;

  /// c2 · Sin calificaciones se muestra "Cliente nuevo".
  bool get esNuevo => promedio == null || totalResenas == 0;
}
