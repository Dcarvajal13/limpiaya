import '../../domain/entities/perfil_publico.dart';
import '../../domain/entities/tipo_limpieza.dart';

/// Conversión de las vistas de Supabase ⇄ [PerfilPublico] (HU-06).
abstract final class PerfilPublicoModel {
  /// Una fila de `trabajadoras_publicas`, con sus reseñas ya cargadas.
  static PerfilPublico desdeJson(
    Map<String, dynamic> fila, {
    required List<Map<String, dynamic>> resenas,
    required String? fotoUrl,
  }) {
    return PerfilPublico(
      id: fila['id'] as String,
      nombre: fila['nombre'] as String,
      fotoUrl: fotoUrl,
      experienciaAnios: (fila['experiencia_anios'] as num?)?.toInt(),
      tarifaReferencia: (fila['tarifa_referencia'] as num?)?.toDouble(),
      descripcion: fila['descripcion'] as String?,
      verificada: fila['verificada'] as bool? ?? false,
      zonas: [
        for (final zona in (fila['zonas'] as List?) ?? const []) zona as String,
      ],
      servicios: [
        for (final tipo in (fila['servicios'] as List?) ?? const [])
          ?_tipo(tipo as String),
      ],
      promedio: (fila['promedio'] as num?)?.toDouble(),
      totalResenas: (fila['total_resenas'] as num?)?.toInt() ?? 0,
      serviciosCompletados:
          (fila['servicios_completados'] as num?)?.toInt() ?? 0,
      resenas: [for (final resena in resenas) resenaDesdeJson(resena)],
      destacada: fila['destacada'] as bool? ?? false,
      zonaIds: [
        for (final id in (fila['zona_ids'] as List?) ?? const [])
          (id as num).toInt(),
      ],
    );
  }

  /// Una fila de `resenas_publicas`.
  static ResenaPublica resenaDesdeJson(Map<String, dynamic> fila) {
    final comentario = (fila['comentario'] as String?)?.trim();
    final respuesta = (fila['respuesta'] as String?)?.trim();
    return ResenaPublica(
      id: fila['id'] as String?,
      estrellas: (fila['estrellas'] as num).toInt(),
      autorNombre: (fila['autor_nombre'] as String?) ?? 'Usuario',
      comentario: (comentario == null || comentario.isEmpty) ? null : comentario,
      createdAt: fila['created_at'] != null
          ? DateTime.parse(fila['created_at'] as String).toLocal()
          : null,
      // HU-31 · Respuesta de quien recibió la reseña.
      respuesta: (respuesta == null || respuesta.isEmpty) ? null : respuesta,
      respuestaEn: fila['respuesta_en'] != null
          ? DateTime.parse(fila['respuesta_en'] as String).toLocal()
          : null,
    );
  }

  /// Un tipo de limpieza guardado como texto; null si la base trae uno nuevo
  /// que esta versión de la app todavía no conoce.
  static TipoLimpieza? _tipo(String valor) {
    for (final tipo in TipoLimpieza.values) {
      if (tipo.valorDb == valor) return tipo;
    }
    return null;
  }
}
