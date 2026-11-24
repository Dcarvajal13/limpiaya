import '../entities/pago.dart';

/// Contrato de los cobros guardados (E9 · Comisión y pagos).
///
/// El cobro lo registra la base a partir de la solicitud: no se le mandan
/// montos desde el teléfono.
abstract interface class PagoRepository {
  /// Cobra la solicitud [solicitudId] y devuelve el pago guardado.
  ///
  /// Es idempotente: si la solicitud ya tenía pago, devuelve el mismo.
  Future<Pago> pagar(String solicitudId);
}
