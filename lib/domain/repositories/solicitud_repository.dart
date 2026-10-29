import '../entities/solicitud.dart';
import '../entities/solicitud_disponible.dart';
import '../entities/zona.dart';
import '../entities/direccion_cliente.dart';
import '../entities/nueva_solicitud.dart';

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

  /// HU-45 · Una solicitud concreta tal como la ve la trabajadora (fecha,
  /// pago, zona, detalles de la vivienda… y NUNCA la dirección exacta).
  /// `null` si no existe o no puede verla.
  Future<SolicitudDisponible?> solicitudDisponible(String id);

  /// HU-07 · Publica una solicitud del cliente con sesión y devuelve su id.
  Future<String> publicar(NuevaSolicitud solicitud);

  /// HU-05 c2 · Zona y dirección guardadas del cliente, para precargarlas.
  Future<DireccionCliente?> miDireccion();

  /// HU-08 · Solicitudes del cliente con sesión, ordenadas por fecha de servicio
  /// con su estado actual (Publicada, Asignada, Completada o Cancelada).
  Future<List<Solicitud>> misSolicitudes();

  /// HU-10 · Cancela una solicitud Publicada del cliente con sesión. Sus
  /// postulaciones pendientes pasan a "Solicitud cancelada".
  Future<void> cancelar(String id, {String? motivo});

  /// HU-09 · Una solicitud del cliente con sesión, con su dirección, para
  /// llenar el formulario de edición. Null si no existe o no es suya.
  Future<Solicitud?> miSolicitud(String id);

  /// HU-09 · Guarda los cambios de una solicitud que sigue Publicada.
  Future<void> editar(String id, NuevaSolicitud datos);
}
