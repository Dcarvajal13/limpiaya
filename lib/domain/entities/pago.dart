import 'metodo_pago.dart';

/// En qué va un cobro (E9 · Comisión y pagos).
enum EstadoPago {
  pendiente('pendiente'),
  aprobado('aprobado'),
  rechazado('rechazado');

  const EstadoPago(this.valorDb);

  /// Valor con el que se guardaría en la base.
  final String valorDb;
}

/// Un cobro del total de una solicitud: lo que recibe la trabajadora más la
/// tarifa de LimpiaYa (HU-52).
///
/// Es una entidad de dominio: no sabe si el cobro lo hizo una pasarela real o
/// la dummy de pruebas.
class Pago {
  const Pago({
    required this.id,
    required this.solicitudId,
    required this.pagoTrabajadora,
    required this.tarifa,
    required this.total,
    required this.metodo,
    required this.estado,
    required this.referencia,
    required this.creadoEn,
    this.motivoRechazo,
  });

  final String id;
  final String solicitudId;

  /// Lo que recibe la trabajadora, en USD.
  final double pagoTrabajadora;

  /// Comisión de LimpiaYa, en USD.
  final double tarifa;

  /// Lo que se le cobró al cliente: [pagoTrabajadora] + [tarifa].
  final double total;

  final MetodoPago metodo;
  final EstadoPago estado;

  /// Código que identifica el cobro (para soporte y conciliación).
  final String referencia;

  final DateTime creadoEn;

  /// Por qué se rechazó, listo para mostrar. Null si no se rechazó.
  final String? motivoRechazo;

  bool get estaAprobado => estado == EstadoPago.aprobado;
  bool get fueRechazado => estado == EstadoPago.rechazado;
}
