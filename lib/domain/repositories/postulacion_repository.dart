import '../entities/postulacion.dart';

/// Contrato de postulaciones: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_postulacion_repository.dart.
abstract interface class PostulacionRepository {
  /// HU-13 · Postulaciones de la trabajadora con sesión, de la más reciente a
  /// la más antigua, cada una con su estado: Pendiente, Aceptada,
  /// No seleccionada o Solicitud cancelada. Las retiradas (HU-26) no se listan.
  Future<List<Postulacion>> misPostulaciones();
}
