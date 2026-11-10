import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/metodo_pago.dart';
import '../../domain/entities/quien_pone_productos.dart';
import '../../domain/entities/servicio_agendado.dart';
import '../../domain/entities/tipo_limpieza.dart';

/// Conversión de una fila de `solicitudes` a la entidad de HU-16.
abstract final class ServicioAgendadoModel {
  /// [soyCliente] indica desde qué lado se está mirando el servicio.
  /// [contraparte] trae nombre, foto y promedio de la otra parte.
  static ServicioAgendado desdeJson(
    Map<String, dynamic> json, {
    required bool soyCliente,
    String? contraparteId,
    String? contraparteNombre,
    String? contraparteFotoUrl,
    double? contrapartePromedio,
    bool yaCalifique = false,
  }) {
    return ServicioAgendado(
      id: json['id'] as String,
      estado: EstadoSolicitud.desdeDb(json['estado'] as String),
      tipo: TipoLimpieza.desdeDb(json['tipo'] as String),
      zona: json['zona'] as String? ?? '',
      inicio: DateTime.parse(json['inicio'] as String).toLocal(),
      horasEstimadas: (json['horas_estimadas'] as num).toDouble(),
      pagoOfrecido: (json['pago_ofrecido'] as num).toDouble(),
      metodoPago: MetodoPago.desdeDb(json['metodo_pago'] as String),
      habitaciones: (json['habitaciones'] as num?)?.toInt() ?? 1,
      banos: (json['banos'] as num?)?.toInt() ?? 1,
      tieneMascotas: json['tiene_mascotas'] as bool? ?? false,
      productosPor: json['productos_por'] != null
          ? QuienPoneProductos.desdeDb(json['productos_por'] as String)
          : null,
      direccion: json['direccion'] as String?,
      puntoReferencia: json['punto_referencia'] as String?,
      notas: json['notas'] as String?,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
      completadaEn: json['completada_en'] != null
          ? DateTime.parse(json['completada_en'] as String).toLocal()
          : null,
      canceladaEn: json['cancelada_en'] != null
          ? DateTime.parse(json['cancelada_en'] as String).toLocal()
          : null,
      contraparteId: contraparteId,
      contraparteNombre: contraparteNombre,
      contraparteFotoUrl: contraparteFotoUrl,
      contrapartePromedio: contrapartePromedio,
      soyCliente: soyCliente,
      yaCalifique: yaCalifique,
    );
  }
}
