import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/movimiento.dart';

/// Enlace de texto con una línea que aparece desde la izquierda al pasar
/// el ratón. En pantallas táctiles no hay hover, así que no se anima.
class EnlaceSubrayado extends StatefulWidget {
  const EnlaceSubrayado({
    super.key,
    required this.texto,
    required this.onTap,
    this.estilo,
    this.colorHover,
  });

  final String texto;
  final VoidCallback onTap;
  final TextStyle? estilo;

  /// Color del texto con el ratón encima (por defecto, el color del texto
  /// principal).
  final Color? colorHover;

  @override
  State<EnlaceSubrayado> createState() => _EnlaceSubrayadoState();
}

class _EnlaceSubrayadoState extends State<EnlaceSubrayado> {
  var _encima = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.estilo ?? DefaultTextStyle.of(context).style;
    final colorEncima = widget.colorHover ?? AppColors.texto;
    final color = _encima ? colorEncima : base.color;

    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _encima = true),
        onExit: (_) => setState(() => _encima = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ConstrainedBox(
            // Área táctil de al menos 44 px de alto.
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: Movimiento.rapido,
                      style: base.copyWith(color: color),
                      child: Text(widget.texto),
                    ),
                    const SizedBox(height: 2),
                    AnimatedScale(
                      scale: _encima ? 1 : 0,
                      alignment: Alignment.centerLeft,
                      duration: Movimiento.normal,
                      curve: Movimiento.salida,
                      child: SizedBox(height: 1, child: ColoredBox(color: color ?? colorEncima)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
