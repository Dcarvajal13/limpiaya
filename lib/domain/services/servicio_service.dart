import '../entities/estado_postulacion.dart';
import '../entities/estado_solicitud.dart';
import '../entities/postulante.dart';
import '../entities/solicitud.dart';

/// Reglas de negocio de los servicios agendados:
/// HU-15 · Elegir a una trabajadora.
/// HU-17 · Marcar un servicio como completado.
/// HU-28 · Cancelar un servicio asignado.
///
/// Vive en el dominio y no conoce Supabase, igual que `PostulacionService`:
/// así las reglas se prueban solas, sin red ni base de datos.
abstract final class ServicioService {
  // --- HU-15 · Elegir a una trabajadora -------------------------------------

  /// Mensajes que devuelve la función `elegir_trabajadora` de la base. Se
  /// muestran tal cual porque ya están escritos para el cliente.
  static const mensajesElegir = [
    'Esta postulación ya no está disponible',
    'Esta solicitud ya tiene una trabajadora asignada',
    'Esta solicitud fue cancelada',
    'La fecha de esta solicitud ya pasó',
    'Esta trabajadora ya tiene un servicio en ese horario',
  ];

  /// Cualquier otro fallo al elegir (sin red, base de datos).
  static const mensajeErrorElegir =
      'No pudimos elegir a la trabajadora. Intenta de nuevo.';

  /// Confirmación al elegir (c1).
  static String mensajeElegida(String nombre) =>
      'Elegiste a $nombre. El servicio quedó agendado.';

  /// c1 y c4 · ¿Se ofrece el botón "Elegir" para esta postulante?
  ///
  /// Solo mientras la solicitud sigue Publicada, la postulante está Pendiente
  /// y todavía no se eligió a nadie. [estadoSolicitud] puede ser null si el
  /// resumen de la solicitud aún no cargó: en ese caso decide la lista de
  /// postulantes, y la base vuelve a revisarlo al confirmar.
  static bool puedeElegir({
    required Postulante postulante,
    required Iterable<Postulante> postulantes,
    EstadoSolicitud? estadoSolicitud,
  }) {
    if (estadoSolicitud != null && estadoSolicitud != EstadoSolicitud.publicada) {
      return false;
    }
    if (postulantes.any((p) => p.estado == EstadoPostulacion.aceptada)) {
      return false;
    }
    return postulante.estado == EstadoPostulacion.pendiente;
  }

  // --- HU-17 · Marcar un servicio como completado ---------------------------

  /// Mensajes que devuelve la función `completar_servicio` de la base.
  static const mensajesCompletar = [
    'No encontramos ese servicio',
    'Solo puedes completar un servicio asignado',
    'El servicio todavía no ha empezado',
  ];

  /// Cualquier otro fallo al completar (sin red, base de datos).
  static const mensajeErrorCompletar =
      'No pudimos marcar el servicio como completado. Intenta de nuevo.';

  /// Confirmación al completar (c1).
  static const mensajeCompletado = 'Servicio completado.';

  /// c1 y c2 · "Marcar como completado" solo se ofrece con el servicio
  /// Asignado y su hora de inicio ya pasada.
  static bool puedeCompletar(Solicitud solicitud, DateTime ahora) =>
      solicitud.estado == EstadoSolicitud.asignada &&
      !solicitud.inicio.isAfter(ahora);

  // --- HU-28 · Cancelar un servicio asignado --------------------------------

  /// Motivos que se ofrecen al cliente.
  static const motivosCancelarCliente = [
    'Cambio de planes',
    'Ya no necesito el servicio',
    'Tuve un imprevisto',
    'Otro',
  ];

  /// Motivos que se ofrecen a la trabajadora.
  static const motivosCancelarTrabajadora = [
    'Tengo un imprevisto',
    'Problema de salud',
    'No puedo llegar a la dirección',
    'Otro',
  ];

  /// c2 · Intentó cancelar sin elegir un motivo.
  static const mensajeEligeMotivo = 'Elige un motivo';

  /// Mensajes que devuelve la función `cancelar_servicio` de la base.
  static const mensajesCancelar = [
    mensajeEligeMotivo,
    'No encontramos ese servicio',
    'Un servicio completado ya no se puede cancelar',
    'Solo puedes cancelar un servicio asignado',
  ];

  /// Cualquier otro fallo al cancelar (sin red, base de datos).
  static const mensajeErrorCancelar =
      'No pudimos cancelar el servicio. Intenta de nuevo.';

  /// Confirmación al cancelar (c1).
  static const mensajeServicioCancelado =
      'Servicio cancelado. Le avisamos a la otra parte con tu motivo.';

  /// c1 y c3 · Solo se cancela un servicio Asignado: uno Completado ya no.
  static bool puedeCancelar(EstadoSolicitud estado) =>
      estado == EstadoSolicitud.asignada;

  /// Si faltan menos de 24 horas, la base la marca como cancelación tardía.
  /// La app lo avisa antes de confirmar.
  static bool esCancelacionTardia(DateTime inicio, DateTime ahora) =>
      inicio.difference(ahora) < const Duration(hours: 24);

  /// Convierte el error de la base en un mensaje para el usuario: si es uno
  /// de [conocidos] lo devuelve tal cual; si no, [porDefecto].
  static String traducir(
    String mensajeDb,
    List<String> conocidos,
    String porDefecto,
  ) {
    for (final mensaje in conocidos) {
      if (mensajeDb.contains(mensaje)) return mensaje;
    }
    return porDefecto;
  }
}
