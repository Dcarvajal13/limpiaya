import '../../domain/entities/metodo_pago.dart';
import '../../domain/entities/pago.dart';

/// Conversión de una fila de `pagos` a la entidad [Pago].
abstract final class PagoModel {
  static Pago desdeJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] as String,
      solicitudId: json['solicitud_id'] as String,
      pagoTrabajadora: (json['pago_trabajadora'] as num).toDouble(),
      tarifa: (json['tarifa'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      metodo: MetodoPago.desdeDb(json['metodo'] as String),
      estado: json['estado'] == 'aprobado'
          ? EstadoPago.aprobado
          : EstadoPago.rechazado,
      referencia: json['referencia'] as String,
      creadoEn: DateTime.parse(json['creado_en'] as String).toLocal(),
      motivoRechazo: json['motivo_rechazo'] as String?,
    );
  }
}
