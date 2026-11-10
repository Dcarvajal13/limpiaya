import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/mi_reputacion.dart';
import '../../domain/repositories/mi_reputacion_repository.dart';
import '../../domain/services/respuesta_service.dart';
import '../models/perfil_publico_model.dart';

/// Implementación de MiReputacionRepository usando Supabase (HU-31).
///
/// Lee las vistas `reputacion`, `resenas_publicas` y `mi_nivel` (HU-61);
/// responde con la función
/// `responder_resena` (migración de HU-31), que valida que la reseña sea mía,
/// que ya se muestre y que no pase de 300 caracteres.
class SupabaseMiReputacionRepository implements MiReputacionRepository {
  SupabaseMiReputacionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<MiReputacion> miReputacion() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      final reputacion = await _client
          .from('reputacion')
          .select('promedio, total_resenas, servicios_completados')
          .eq('usuario_id', usuario.id)
          .maybeSingle();

      final filas = await _client
          .from('resenas_publicas')
          .select(
            'id, estrellas, comentario, autor_nombre, created_at, '
            'respuesta, respuesta_en',
          )
          .eq('destinatario_id', usuario.id)
          .order('created_at', ascending: false)
          .limit(50);

      // HU-61 · Mi nivel. Complementario: si falla, la pantalla sale sin
      // la insignia en vez de romperse.
      Map<String, dynamic>? nivel;
      try {
        nivel = await _client
            .from('mi_nivel')
            .select('destacada, cancelaciones_tardias')
            .maybeSingle();
      } on Exception {
        nivel = null;
      }

      return MiReputacion(
        promedio: (reputacion?['promedio'] as num?)?.toDouble(),
        totalResenas: (reputacion?['total_resenas'] as num?)?.toInt() ?? 0,
        serviciosCompletados:
            (reputacion?['servicios_completados'] as num?)?.toInt() ?? 0,
        resenas: [
          for (final fila in filas)
            PerfilPublicoModel.resenaDesdeJson(Map<String, dynamic>.from(fila)),
        ],
        destacada: nivel?['destacada'] as bool? ?? false,
        cancelacionesTardias:
            (nivel?['cancelaciones_tardias'] as num?)?.toInt() ?? 0,
      );
    } on Exception {
      throw const AppException('No pudimos cargar tu reputación.');
    }
  }

  @override
  Future<void> responder({
    required String calificacionId,
    required String texto,
  }) async {
    try {
      await _client.rpc(
        'responder_resena',
        params: {'p_calificacion': calificacionId, 'p_texto': texto.trim()},
      );
    } on PostgrestException catch (e) {
      throw AppException(_traducir(e.message));
    } on Exception {
      throw const AppException(RespuestaService.mensajeError);
    }
  }

  /// Mensajes de la función de la base → mensajes para la trabajadora.
  static String _traducir(String mensaje) {
    if (mensaje.contains('300 caracteres')) {
      return RespuestaService.mensajeLimite;
    }
    if (mensaje.contains('Escribe tu respuesta')) {
      return RespuestaService.mensajeVacia;
    }
    if (mensaje.contains('Solo puedes responder')) {
      return RespuestaService.mensajeNoPermitida;
    }
    return RespuestaService.mensajeError;
  }
}
