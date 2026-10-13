import '../entities/solicitud_disponible.dart';
import '../entities/zona.dart';

/// Contrato de solicitudes: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_solicitud_repository.dart.
/// Cada historia que trabaje con solicitudes agrega aquí su método.
abstract interface class SolicitudRepository {
  /// Zonas donde trabaja quien inició sesión (HU-04 las guarda en su perfil).
  Future<List<Zona>> misZonas();

  /// HU-11 · Solicitudes Publicadas, con fecha futura y de las zonas de la
  /// trabajadora, ordenadas de la más próxima a la más lejana.
  Future<List<SolicitudDisponible>> disponibles();
}
