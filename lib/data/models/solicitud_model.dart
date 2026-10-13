import '../../domain/entities/metodo_pago.dart';
import '../../domain/entities/solicitud_disponible.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';

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
}
