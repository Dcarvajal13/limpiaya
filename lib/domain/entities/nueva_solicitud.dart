import 'metodo_pago.dart';
import 'quien_pone_productos.dart';
import 'tipo_limpieza.dart';

/// Lo que llena el cliente para publicar una solicitud (HU-07 y HU-43).
class NuevaSolicitud {
  const NuevaSolicitud({
    required this.tipo,
    required this.zonaId,
    required this.direccion,
    this.puntoReferencia,
    required this.inicio,
    required this.horasEstimadas,
    required this.pagoOfrecido,
    required this.metodoPago,
    required this.habitaciones,
    required this.banos,
    required this.tieneMascotas,
    required this.productosPor,
    this.notas,
  });

  final TipoLimpieza tipo;
  final int zonaId;

  /// Privada: solo la ve la trabajadora elegida (HU-05 c3).
  final String direccion;
  final String? puntoReferencia;

  /// Fecha y hora de inicio, en la hora local de quien publica.
  final DateTime inicio;
  final double horasEstimadas;

  /// Monto en USD que recibe la trabajadora (sin la tarifa de LimpiaYa).
  final double pagoOfrecido;
  final MetodoPago metodoPago;

  final int habitaciones;
  final int banos;
  final bool tieneMascotas;

  /// Puede venir vacío desde la pantalla; el servicio lo exige (HU-43 c2).
  final QuienPoneProductos? productosPor;
  final String? notas;
}