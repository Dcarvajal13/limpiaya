import '../../domain/entities/verificacion_pendiente.dart';

/// Conversión de las filas de Supabase a VerificacionPendiente.
///
/// La consulta trae la verificación con los datos de la cuenta anidados:
///   { id, trabajadora_id, created_at, cedula_path, selfie_path,
///     trabajadoras: { perfiles: { nombre, telefono, foto_path, created_at } } }
abstract final class VerificacionModel {
  static Map<String, dynamic>? _perfil(Map<String, dynamic> json) {
    final trabajadora = json['trabajadoras'];
    if (trabajadora is! Map) return null;
    final perfil = trabajadora['perfiles'];
    return perfil is Map ? Map<String, dynamic>.from(perfil) : null;
  }

  /// Ruta de la foto de perfil dentro del bucket "avatars", si tiene.
  static String? fotoPath(Map<String, dynamic> json) =>
      _perfil(json)?['foto_path'] as String?;

  static VerificacionPendiente pendienteDesdeJson(
    Map<String, dynamic> json, {
    String? fotoUrl,
    String? cedulaUrl,
    String? selfieUrl,
  }) {
    final perfil = _perfil(json);
    final enviada = DateTime.parse(json['created_at'] as String).toLocal();
    final creada = perfil?['created_at'] as String?;

    return VerificacionPendiente(
      id: json['id'] as String,
      trabajadoraId: json['trabajadora_id'] as String,
      nombre: (perfil?['nombre'] as String?) ?? 'Sin nombre',
      telefono: perfil?['telefono'] as String?,
      fotoUrl: fotoUrl,
      cedulaUrl: cedulaUrl,
      selfieUrl: selfieUrl,
      enviada: enviada,
      cuentaCreada: creada == null ? enviada : DateTime.parse(creada).toLocal(),
    );
  }
}
