import '../entities/calificacion.dart';
import '../entities/motivo_calificacion_baja.dart';

/// Contrato de calificaciones: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_calificacion_repository.dart.
abstract interface class CalificacionRepository {
  /// La calificación que ya dejé en ese servicio, o null si todavía no
  /// califiqué (HU-29 c3).
  Future<Calificacion?> miCalificacion(String solicitudId);

  /// HU-29 / HU-30 · Califica a la otra parte de un servicio Completado, de
  /// 1 a 5 estrellas y con un comentario opcional. [motivo] lo exige la app
  /// cuando la trabajadora pone 1 o 2 estrellas al cliente (HU-30 c2).
  ///
  /// Lanza `AppException` si ya calificó ese servicio o si no está
  /// Completado.
  Future<void> calificar({
    required String solicitudId,
    required String destinatarioId,
    required int estrellas,
    String? comentario,
    MotivoCalificacionBaja? motivo,
  });
}
