import '../../domain/entities/estado_postulacion.dart';
import '../../domain/entities/postulante.dart';

/// Conversión JSON de Supabase → entidad Postulante (HU-14).
abstract final class PostulanteModel {
  /// [postulacion]: fila de la tabla `postulaciones`.
  /// [trabajadora]: fila de la vista `trabajadoras_publicas` (puede faltar).
  static Postulante desdeJson(
    Map<String, dynamic> postulacion, {
    Map<String, dynamic>? trabajadora,
    String? fotoUrl,
  }) {
    final estadoDb = postulacion['estado'] as String;
    return Postulante(
      postulacionId: postulacion['id'] as String,
      trabajadoraId: postulacion['trabajadora_id'] as String,
      nombre: (trabajadora?['nombre'] as String?) ?? 'Trabajadora',
      estado: EstadoPostulacion.values.firstWhere(
        (e) => e.valorDb == estadoDb,
      ),
      fecha: DateTime.parse(postulacion['created_at'] as String).toLocal(),
      fotoUrl: fotoUrl,
      // null si todavía no tiene reseñas visibles (HU-29 c4).
      promedio: (trabajadora?['promedio'] as num?)?.toDouble(),
      mensaje: postulacion['mensaje'] as String?,
      // Si la vista no respondió, se asume verificada: la base solo deja
      // postularse con la identidad aprobada (puede_postularse).
      verificada: (trabajadora?['verificada'] as bool?) ?? true,
      experienciaAnios: (trabajadora?['experiencia_anios'] as num?)?.toInt(),
      serviciosCompletados:
          (trabajadora?['servicios_completados'] as num?)?.toInt() ?? 0,
      totalResenas: (trabajadora?['total_resenas'] as num?)?.toInt() ?? 0,
    );
  }
}