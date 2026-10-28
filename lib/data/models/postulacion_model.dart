import '../../domain/entities/estado_postulacion.dart';
import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/tipo_limpieza.dart';

/// Conversión JSON de Supabase ⇄ entidad de postulaciones.
abstract final class PostulacionModel {
  /// Una fila de `postulaciones` más su fila de `solicitudes_publicas`.
  ///
  /// [miId] sirve para saber si la solicitud quedó asignada a mí o a otra
  /// trabajadora. [clienteNombre] y [clienteFotoUrl] los pasa el repositorio.
  static Postulacion desdeJson(
    Map<String, dynamic> postulacion,
    Map<String, dynamic> solicitud, {
    required String miId,
    String? clienteNombre,
    String? clienteFotoUrl,
  }) {
    return Postulacion(
      id: postulacion['id'] as String,
      solicitudId: postulacion['solicitud_id'] as String,
      estado: EstadoPostulacion.resolver(
        guardado: EstadoPostulacion.desdeDb(postulacion['estado'] as String),
        estadoSolicitud: EstadoSolicitud.desdeDb(solicitud['estado'] as String),
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
      creadaEn: postulacion['created_at'] != null
          ? DateTime.parse(postulacion['created_at'] as String).toLocal()
          : null,
    );
  }
}
