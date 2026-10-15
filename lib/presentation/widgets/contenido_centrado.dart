import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Centra el contenido con un ancho máximo de 1200 px (como el prototipo)
/// y deja el margen lateral correcto en móvil y escritorio.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({
    super.key,
    required this.child,
    this.anchoMaximo = Responsive.anchoMaximo,
    this.vertical = 0,
  });

  final Widget child;
  final double anchoMaximo;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.margen(context),
            vertical: vertical,
          ),
          child: child,
        ),
      ),
    );
  }
}
