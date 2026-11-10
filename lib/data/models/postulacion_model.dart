import '../../domain/entities/estado_postulacion.dart';
import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/tipo_limpieza.dart';

/// Conversión JSON de Supabase ⇄ entidad de postulaciones.
abstract final class PostulacionModel {
  /// Una fila de `postulaciones` más su fila de `solicitudes_publicas`.
  ///
  /// [miId] sirve para saber si la solicitud quedó asignada a mí o a otra
  /// trabajadora. [clienteNombre] y [clienteFotoUrl] los pasa el repositorio,
  /// y también [direccion] y [puntoReferencia] cuando me eligieron (HU-15 c3).
  static Postulacion desdeJson(
    Map<String, dynamic> postulacion,
    Map<String, dynamic> solicitud, {
    required String miId,
    String? clienteNombre,
    String? clienteFotoUrl,
    String? direccion,
    String? puntoReferencia,
    int? miCalificacion,
  }) {
    final estadoSolicitud =
        EstadoSolicitud.desdeDb(solicitud['estado'] as String);
    return Postulacion(
      id: postulacion['id'] as String,
      solicitudId: postulacion['solicitud_id'] as String,
      estado: EstadoPostulacion.resolver(
        guardado: EstadoPostulacion.desdeDb(postulacion['estado'] as String),
        estadoSolicitud: estadoSolicitud,
        trabajadoraAsignadaId: solicitud['trabajadora_id'] as String?,
        miId: miId,
      ),
      tipo: TipoLimpieza.desdeDb(solicitud['tipo'] as String),
      zona: solicitud['zona'] as String? ?? '',
      // Supabase entrega la fecha en UTC; se muestra en la hora local.
      inicio: DateTime.parse(solicitud['inicio'] as String).toLocal(),
      horasEstimadas: (solicitud['horas_estimadas'] as num).toDouble(),
      pagoOfrecido: (solicitud['pago_ofrecido'] as num).toDouble(),
      clienteNombre: clienteNombre,
      clienteFotoUrl: clienteFotoUrl,
      direccion: direccion,
      puntoReferencia: puntoReferencia,
      estadoSolicitud: estadoSolicitud,
      motivoCancelacion: solicitud['motivo_cancelacion'] as String?,
      canceladaPorMi: solicitud['cancelada_por'] == miId,
      clienteId: solicitud['cliente_id'] as String?,
      miCalificacion: miCalificacion,
      creadaEn: postulacion['created_at'] != null
          ? DateTime.parse(postulacion['created_at'] as String).toLocal()
          : null,
    );
  }
}
