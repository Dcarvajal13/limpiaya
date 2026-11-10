import '../entities/servicio_agendado.dart';

/// Contrato de servicios: lo que pasa con una solicitud desde que el cliente
/// elige a una trabajadora. QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_servicio_repository.dart. Cada cambio de estado
/// es una función de Postgres, porque nadie puede escribir la columna
/// `estado` directamente (HD-04).
abstract interface class ServicioRepository {
  /// HU-15 · El cliente elige a una postulante: la solicitud pasa a Asignada,
  /// esa postulación a Aceptada y las demás pendientes a No seleccionada.
  ///
  /// Lanza `AppException` con el mensaje que debe ver el cliente si la
  /// solicitud ya no está Publicada, la postulante se retiró o ya tiene otro
  /// servicio en ese horario.
  Future<void> elegir(String postulacionId);

  /// HU-17 · El cliente confirma que la limpieza se hizo: el servicio
  /// Asignado pasa a Completado y desde ahí se puede calificar (HU-29).
  ///
  /// Lanza `AppException` si todavía no ha empezado o ya no está Asignado.
  Future<void> completar(String solicitudId);

  /// HU-16 c1 y c3 · Servicios de la trabajadora con sesión: asignados,
  /// completados y cancelados, ordenados del más cercano al más lejano.
  Future<List<ServicioAgendado>> misServicios();

  /// HU-16 c2 · Un servicio concreto con todos sus datos, incluida la
  /// dirección. Solo devuelve algo si quien mira es el cliente dueño o la
  /// trabajadora asignada (RLS). Null si no existe o no puede verlo.
  Future<ServicioAgendado?> servicioAgendado(String id);
}
