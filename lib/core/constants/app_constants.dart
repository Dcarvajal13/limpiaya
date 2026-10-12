/// Valores fijos del negocio. Si una regla usa un número "mágico",
/// va aquí para que todos usen el mismo.
abstract final class AppConstants {
  /// Tarifa de servicio de LimpiaYa sobre el pago a la trabajadora (HU-52).
  static const double comisionLimpiaYa = 0.10;

  /// Largo mínimo de contraseña (HU-01, criterio 4).
  static const int largoMinimoPassword = 8;

  /// Tamaño máximo de una foto subida: 5 MB (HU-04, criterio 4).
  static const int tamanoMaximoFotoBytes = 5 * 1024 * 1024;

  /// Largo máximo de un mensaje del chat (HU-38, criterio 5).
  static const int largoMaximoMensaje = 500;
}
