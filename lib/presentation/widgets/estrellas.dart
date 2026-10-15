import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Estrellas de calificación.
///
/// - Para mostrar un promedio: `Estrellas(valor: 4.6)`
/// - Para elegir (HU-29, HU-30): `Estrellas(valor: actual, onChanged: (v) => ...)`
class Estrellas extends StatelessWidget {
  const Estrellas({
    super.key,
    required this.valor,
    this.onChanged,
    this.tamano = 18,
  });

  /// Entre 0 y 5. Se redondea a media estrella al mostrar.
  final double valor;

  final ValueChanged<int>? onChanged;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final elegible = onChanged != null;
    final iconos = List.generate(5, (i) {
      final posicion = i + 1;
      final IconData icono;
      if (valor >= posicion) {
        icono = Icons.star_rounded;
      } else if (!elegible && valor >= posicion - 0.5) {
        icono = Icons.star_half_rounded;
      } else {
        icono = Icons.star_outline_rounded;
      }
      final estrella = Icon(icono, size: tamano, color: AppColors.ambar);

      if (!elegible) return estrella;
      return IconButton(
        tooltip: '$posicion de 5',
        onPressed: () => onChanged!(posicion),
        icon: estrella,
      );
    });

    return Semantics(
      label: 'Calificación: ${valor.toStringAsFixed(1)} de 5',
      child: Row(mainAxisSize: MainAxisSize.min, children: iconos),
    );
  }
}
