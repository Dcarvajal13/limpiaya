import 'estado_solicitud.dart';
import 'metodo_pago.dart';
import 'quien_pone_productos.dart';
import 'tipo_limpieza.dart';

/// Solicitud de limpieza creada por un cliente (HU-08).
///
/// Contiene toda la información del servicio publicado, su estado actual y el
/// número de trabajadoras postuladas.
class Solicitud {
  const Solicitud({
    required this.id,
    required this.clienteId,
    this.trabajadoraId,
    this.trabajadoraNombre,
    this.trabajadoraPromedio,
    required this.estado,
    required this.tipo,
    required this.zonaId,
    required this.zona,
    required this.inicio,
    required this.horasEstimadas,
    required this.pagoOfrecido,
    required this.metodoPago,
    required this.numPostulantes,
    this.habitaciones = 1,
    this.banos = 1,
    this.tieneMascotas = false,
    this.productosPor,
    this.direccion,
    this.puntoReferencia,
    this.notas,
    this.createdAt,
    this.motivoCancelacion,
  });

  final String id;
  final String clienteId;
  final String? trabajadoraId;

  /// Nombre de la trabajadora asignada (HU-08), o null si aún no hay.
  final String? trabajadoraNombre;

  /// Promedio de la trabajadora asignada (1 a 5), o null si no tiene reseñas.
  final double? trabajadoraPromedio;

  final EstadoSolicitud estado;
  final TipoLimpieza tipo;
  final int zonaId;

  /// Nombre de la zona (ej. "Los Palos Grandes").
  final String zona;

  /// Fecha y hora de inicio en hora local.
  final DateTime inicio;

  final double horasEstimadas;

  /// Monto ofrecido en USD.
  final double pagoOfrecido;

  final MetodoPago metodoPago;

  /// Cantidad de postulantes pendientes o aceptadas.
  final int numPostulantes;

  final int habitaciones;
  final int banos;
  final bool tieneMascotas;
  final QuienPoneProductos? productosPor;
  final String? direccion;
  final String? puntoReferencia;
  final String? notas;
  final DateTime? createdAt;

  /// Motivo que eligió el cliente al cancelarla (HU-10), si eligió uno.
  final String? motivoCancelacion;
}
