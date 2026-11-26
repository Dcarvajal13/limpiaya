import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/movimiento.dart';

/// Enlace de texto con una línea que aparece desde la izquierda al pasar
/// el ratón. En pantallas táctiles no hay hover, así que no se anima.
///
/// Accesibilidad (WCAG 2.1.1 y 2.4.7): antes era solo un GestureDetector y
/// no se podía llegar a él con Tab. Ahora recibe el foco del teclado, se
/// activa con Enter o Espacio y muestra un borde (y el subrayado) cuando
/// tiene el foco.
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
  var _foco = false;

  /// Enter y Espacio llegan como estas dos intenciones (en la web, Enter
  /// manda ButtonActivateIntent; en las demás plataformas, ActivateIntent).
  late final Map<Type, Action<Intent>> _acciones = {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _activar()),
    ButtonActivateIntent:
        CallbackAction<ButtonActivateIntent>(onInvoke: (_) => _activar()),
  };

  Object? _activar() {
    widget.onTap();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.estilo ?? DefaultTextStyle.of(context).style;
    final colorEncima = widget.colorHover ?? AppColors.texto;
    final color = _encima ? colorEncima : base.color;
    final subrayado = _encima || _foco;

    // El anillo usa el color del texto: si el texto se lee sobre ese fondo,
    // el anillo también se ve (claro sobre oscuro y viceversa).
    final colorAnillo = base.color ?? AppColors.foco;

    return Semantics(
      link: true,
      child: FocusableActionDetector(
        actions: _acciones,
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (valor) => setState(() => _encima = valor),
        onShowFocusHighlight: (valor) => setState(() => _foco = valor),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ConstrainedBox(
            // Área táctil de al menos 44 px de alto.
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IntrinsicWidth(
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
                          scale: subrayado ? 1 : 0,
                          alignment: Alignment.centerLeft,
                          duration: Movimiento.normal,
                          curve: Movimiento.salida,
                          child: SizedBox(
                            height: 1,
                            child: ColoredBox(color: color ?? colorEncima),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Anillo de foco por fuera del texto: no mueve nada de
                  // lugar porque está en un Positioned con márgenes negativos.
                  if (_foco)
                    Positioned(
                      left: -6,
                      right: -6,
                      top: -4,
                      bottom: -4,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: colorAnillo, width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
