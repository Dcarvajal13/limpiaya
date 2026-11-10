import '../entities/mi_reputacion.dart';

/// Contrato de "Mi reputación" (HU-31): QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_mi_reputacion_repository.dart.
abstract interface class MiReputacionRepository {
  /// Mi promedio, mis servicios completados y las reseñas que me dejaron,
  /// cada una con mi respuesta si ya respondí.
  Future<MiReputacion> miReputacion();

  /// HU-31 · Publica mi respuesta a una reseña. Si ya había respondido, la
  /// reemplaza (c2: se edita, nunca hay dos).
  Future<void> responder({
    required String calificacionId,
    required String texto,
  });
}
