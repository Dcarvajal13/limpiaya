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

  /// HU-12 · Postularse a una solicitud Publicada, con un mensaje corto
  /// opcional (máximo 300 caracteres, lo valida la base de datos).
  ///
  /// Antes de insertar comprueba las reglas de negocio y lanza `AppException`
  /// con el mensaje que debe ver la trabajadora:
  /// - c2 · ya se postuló a esa solicitud.
  /// - c3 · se cruza con un servicio que ya tiene asignado.
  Future<void> postular({required String solicitudId, String? mensaje});
}
