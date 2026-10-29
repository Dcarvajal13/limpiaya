import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/metodo_pago.dart';
import '../../domain/entities/quien_pone_productos.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/solicitud_disponible.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';
import '../../domain/entities/direccion_cliente.dart';
import '../../domain/entities/nueva_solicitud.dart';

/// Conversión JSON de Supabase ⇄ entidades de solicitudes.
abstract final class SolicitudModel {
  /// Una fila de la tabla `zonas`.
  static Zona zonaDesdeJson(Map<String, dynamic> json) {
    return Zona.desdeFila(json);
  }

  /// Una fila de la vista `solicitudes_publicas`.
  static SolicitudDisponible disponibleDesdeJson(Map<String, dynamic> json) {
    return SolicitudDisponible(
      id: json['id'] as String,
      tipo: TipoLimpieza.desdeDb(json['tipo'] as String),
      zonaId: json['zona_id'] as int,
      zona: json['zona'] as String,
      // Supabase entrega la fecha en UTC; se muestra en la hora local.
      inicio: DateTime.parse(json['inicio'] as String).toLocal(),
      horasEstimadas: (json['horas_estimadas'] as num).toDouble(),
      pagoOfrecido: (json['pago_ofrecido'] as num).toDouble(),
      metodoPago: MetodoPago.desdeDb(json['metodo_pago'] as String),
      numPostulantes: (json['num_postulantes'] as num?)?.toInt() ?? 0,
      habitaciones: (json['habitaciones'] as num?)?.toInt() ?? 1,
      banos: (json['banos'] as num?)?.toInt() ?? 1,
      tieneMascotas: json['tiene_mascotas'] as bool? ?? false,
      productosPor: QuienPoneProductos.desdeDb(
        json['productos_por'] as String? ??
            QuienPoneProductos.cliente.valorDb,
      ),
    );
  }

  /// Una solicitud del cliente desde la base de datos o vista (HU-08).
  ///
  /// [trabajadoraNombre] y [trabajadoraPromedio] se pasan desde el
  /// repositorio, que los obtiene de `trabajadoras_publicas`.
  static Solicitud solicitudDesdeJson(
    Map<String, dynamic> json, {
    String? trabajadoraNombre,
    double? trabajadoraPromedio,
  }) {
    return Solicitud(
      id: json['id'] as String,
      clienteId: json['cliente_id'] as String,
      trabajadoraId: json['trabajadora_id'] as String?,
      trabajadoraNombre: trabajadoraNombre,
      trabajadoraPromedio: trabajadoraPromedio,
      estado: EstadoSolicitud.desdeDb(json['estado'] as String),
      tipo: TipoLimpieza.desdeDb(json['tipo'] as String),
      zonaId: json['zona_id'] as int,
      zona: json['zona'] as String? ?? '',
      inicio: DateTime.parse(json['inicio'] as String).toLocal(),
      horasEstimadas: (json['horas_estimadas'] as num).toDouble(),
      pagoOfrecido: (json['pago_ofrecido'] as num).toDouble(),
      metodoPago: MetodoPago.desdeDb(json['metodo_pago'] as String),
      numPostulantes: (json['num_postulantes'] as num?)?.toInt() ?? 0,
      habitaciones: (json['habitaciones'] as num?)?.toInt() ?? 1,
      banos: (json['banos'] as num?)?.toInt() ?? 1,
      tieneMascotas: json['tiene_mascotas'] as bool? ?? false,
      productosPor: json['productos_por'] != null
          ? QuienPoneProductos.desdeDb(json['productos_por'] as String)
          : null,
      direccion: json['direccion'] as String?,
      puntoReferencia: json['punto_referencia'] as String?,
      notas: json['notas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      motivoCancelacion: json['motivo_cancelacion'] as String?,
    );
  }

  /// Una solicitud nueva convertida en la fila que se inserta en `solicitudes`.
  /// Solo lleva las columnas que la base permite escribir.
  static Map<String, dynamic> nuevaAJson(
    NuevaSolicitud solicitud,
    String clienteId,
  ) {
    return {
      'cliente_id': clienteId,
      'tipo': solicitud.tipo.valorDb,
      'zona_id': solicitud.zonaId,
      'direccion': solicitud.direccion,
      'punto_referencia': solicitud.puntoReferencia,
      // La base guarda en UTC; se envía la hora local convertida.
      'inicio': solicitud.inicio.toUtc().toIso8601String(),
      'horas_estimadas': solicitud.horasEstimadas,
      'pago_ofrecido': solicitud.pagoOfrecido,
      'metodo_pago': solicitud.metodoPago.valorDb,
      'habitaciones': solicitud.habitaciones,
      'banos': solicitud.banos,
      'tiene_mascotas': solicitud.tieneMascotas,
      'productos_por': solicitud.productosPor!.valorDb,
      'notas': solicitud.notas,
    };
  }

  /// Una fila de la tabla `clientes`.
  static DireccionCliente direccionDesdeJson(Map<String, dynamic> json) {
    return DireccionCliente(
      zonaId: json['zona_id'] as int?,
      direccion: json['direccion'] as String?,
      puntoReferencia: json['punto_referencia'] as String?,
    );
  }
}
