import '../../domain/entities/metodo_pago.dart';
import '../../domain/entities/solicitud_disponible.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';
import '../../domain/entities/direccion_cliente.dart';
import '../../domain/entities/nueva_solicitud.dart';
/// Conversión JSON de Supabase ⇄ entidades de solicitudes.
abstract final class SolicitudModel {
  /// Una fila de la tabla `zonas`.
  static Zona zonaDesdeJson(Map<String, dynamic> json) {
    return Zona(id: json['id'] as int, nombre: json['nombre'] as String);
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
