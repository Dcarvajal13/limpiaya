import 'metodo_pago.dart';
import 'quien_pone_productos.dart';
import 'tipo_limpieza.dart';

/// Solicitud publicada que una trabajadora puede ver (HU-11).
///
/// Viene de la vista `solicitudes_publicas`, que NO incluye la dirección
/// exacta ni el punto de referencia (esos datos son privados hasta que la
/// trabajadora es elegida).
class SolicitudDisponible {
  const SolicitudDisponible({
    required this.id,
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
    this.productosPor = QuienPoneProductos.cliente,
  });

  final String id;
  final TipoLimpieza tipo;
  final int zonaId;

  /// Nombre de la zona, por ejemplo "Los Palos Grandes".
  final String zona;

  /// Fecha y hora de inicio, en la hora local de quien la mira.
  final DateTime inicio;

  /// Puede tener decimales (4.5 horas).
  final double horasEstimadas;

  /// Monto en USD que recibe la trabajadora.
  final double pagoOfrecido;
  final MetodoPago metodoPago;

  /// Postulaciones pendientes o aceptadas (HU-12).
  final int numPostulantes;

  /// Tamaño de la casa (por defecto 1 y 1, igual que en la tabla).
  final int habitaciones;
  final int banos;

  /// Si en la casa hay mascotas (filtro "Sin mascotas").
  final bool tieneMascotas;

  /// HU-43 · Quién lleva los productos de limpieza. La trabajadora lo ve en la
  /// tarjeta antes de postularse.
  final QuienPoneProductos productosPor;
}
