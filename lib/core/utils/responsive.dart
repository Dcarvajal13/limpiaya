import 'package:flutter/widgets.dart';

/// Tamaños de pantalla. El prototipo cambia a una columna por debajo de 800 px.
abstract final class Responsive {
  static const anchoMovil = 800.0;

  /// Ancho máximo del contenido en escritorio (como el prototipo).
  static const anchoMaximo = 1200.0;

  static bool esMovil(BuildContext context) =>
      MediaQuery.sizeOf(context).width < anchoMovil;

  /// Margen lateral: 16 en móvil, 24 en escritorio.
  static double margen(BuildContext context) => esMovil(context) ? 16 : 24;
}
