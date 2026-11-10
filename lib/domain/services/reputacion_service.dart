/// Textos de reputación que se repiten en varias pantallas (HU-46).
///
/// Vive en el dominio y no conoce Flutter, así se prueba fácil
/// (test/domain/services/reputacion_service_test.dart).
abstract final class ReputacionService {
  /// HU-46 c2 · Cliente sin calificaciones.
  static const clienteNuevo = 'Cliente nuevo';

  /// "1 servicio completado" / "3 servicios completados".
  static String servicios(int cantidad) => cantidad == 1
      ? '1 servicio completado'
      : '$cantidad servicios completados';

  /// "1 reseña" / "4 reseñas".
  static String resenas(int cantidad) =>
      cantidad == 1 ? '1 reseña' : '$cantidad reseñas';

  /// 4.9 → "4,9".
  static String promedio(double valor) =>
      valor.toStringAsFixed(1).replaceAll('.', ',');

  /// HU-46 c1 y c2 · "★ 4,8 · 3 servicios completados" o "Cliente nuevo".
  static String cliente({
    required double? promedio,
    required int totalResenas,
    required int serviciosCompletados,
  }) {
    if (promedio == null || totalResenas == 0) return clienteNuevo;
    return '★ ${ReputacionService.promedio(promedio)} · '
        '${servicios(serviciosCompletados)}';
  }
}
