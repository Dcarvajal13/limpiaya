import 'package:flutter/material.dart';

import 'pie_pagina.dart';

/// Reemplaza a `SingleChildScrollView` en las pantallas: desplaza el
/// contenido y pone el [PiePagina] al final.
///
/// Si el contenido es corto, el pie queda pegado al borde de abajo de la
/// pantalla en vez de flotar a la mitad.
class DesplazableConPie extends StatelessWidget {
  const DesplazableConPie({
    super.key,
    required this.child,
    this.controller,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final ScrollController? controller;

  /// Espacio alrededor del contenido (no del pie).
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) => SingleChildScrollView(
        controller: controller,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                restricciones.maxHeight.isFinite ? restricciones.maxHeight : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: padding, child: child),
              const PiePagina(),
            ],
          ),
        ),
      ),
    );
  }
}
