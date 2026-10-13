/// Cómo paga el cliente (enum `metodo_pago` en la base).
enum MetodoPago {
  pagoMovil('pago_movil', 'Pago Móvil'),
  efectivoUsd('efectivo_usd', 'Efectivo USD'),
  efectivoBs('efectivo_bs', 'Efectivo Bs.'),
  transferencia('transferencia', 'Transferencia');

  const MetodoPago(this.valorDb, this.etiqueta);

  /// Valor exacto con el que se guarda en Supabase.
  final String valorDb;

  /// Texto que ve la persona en pantalla.
  final String etiqueta;

  static MetodoPago desdeDb(String valor) =>
      MetodoPago.values.firstWhere((metodo) => metodo.valorDb == valor);
}
