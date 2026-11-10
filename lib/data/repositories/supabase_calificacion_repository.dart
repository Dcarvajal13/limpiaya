import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/calificacion.dart';
import '../../domain/entities/motivo_calificacion_baja.dart';
import '../../domain/repositories/calificacion_repository.dart';
import '../../domain/services/calificacion_service.dart';

/// Implementación de CalificacionRepository usando Supabase.
///
/// Escribe en la tabla `calificaciones`: la política RLS "calificar a la otra
/// parte" (puede_calificar) solo deja calificar a la otra parte de un
/// servicio Completado, y el índice único (solicitud_id, autor_id) impide
/// calificar dos veces (HU-29 c3).
class SupabaseCalificacionRepository implements CalificacionRepository {
  SupabaseCalificacionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Calificacion?> miCalificacion(String solicitudId) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    try {
      // RLS: cada quien lee las calificaciones que escribió.
      final fila = await _client
          .from('calificaciones')
          .select('solicitud_id, estrellas, comentario, created_at')
          .eq('solicitud_id', solicitudId)
          .eq('autor_id', usuario.id)
          .maybeSingle();
      if (fila == null) return null;
      return Calificacion(
        solicitudId: fila['solicitud_id'] as String,
        estrellas: (fila['estrellas'] as num).toInt(),
        comentario: fila['comentario'] as String?,
        fecha: fila['created_at'] == null
            ? null
            : DateTime.parse(fila['created_at'] as String).toLocal(),
      );
    } on Exception {
      throw const AppException('No pudimos cargar tu calificación.');
    }
  }

  @override
  Future<void> calificar({
    required String solicitudId,
    required String destinatarioId,
    required int estrellas,
    String? comentario,
    MotivoCalificacionBaja? motivo,
  }) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    if (!CalificacionService.estrellasValidas(estrellas)) {
      throw const AppException(CalificacionService.mensajeEligeEstrellas);
    }
    try {
      await _client.from('calificaciones').insert({
        'solicitud_id': solicitudId,
        'autor_id': usuario.id,
        'destinatario_id': destinatarioId,
        'estrellas': estrellas,
        'comentario': CalificacionService.limpiarComentario(comentario),
        'motivo': motivo?.valorDb,
      });
    } on PostgrestException catch (e) {
      // 23505: ya existe una calificación mía para ese servicio (c3).
      if (e.code == '23505') {
        throw const AppException(CalificacionService.mensajeYaCalificaste);
      }
      // 42501: la política no lo deja (el servicio no está Completado).
      if (e.code == '42501') {
        throw const AppException(CalificacionService.mensajeNoCompletado);
      }
      throw const AppException(CalificacionService.mensajeError);
    } on Exception {
      throw const AppException(CalificacionService.mensajeError);
    }
  }
}
