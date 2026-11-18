import 'package:flutter/material.dart';

import '../../core/theme/movimiento.dart';

/// Hace aparecer a [child] una sola vez: sube unos píxeles mientras se
/// vuelve visible. Sirve para escalonar la entrada de una pantalla con
/// [retraso] distintos (0, 60, 120 ms...).
///
/// Si el sistema pide reducir el movimiento, [child] se muestra de una vez.
class Aparecer extends StatefulWidget {
  const Aparecer({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
    this.desde = 14,
    this.duracion = Movimiento.entrada,
  });

  final Widget child;
  final Duration retraso;

  /// Cuántos píxeles más abajo empieza.
  final double desde;
  final Duration duracion;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer> with SingleTickerProviderStateMixin {
  late final AnimationController _control;
  late final Animation<double> _avance;
  var _iniciado = false;

  @override
  void initState() {
    super.initState();
    final total = widget.retraso + widget.duracion;
    _control = AnimationController(vsync: this, duration: total);
    // El retraso va dentro de la misma animación (y no con un Timer), así
    // no queda nada pendiente si la pantalla se cierra antes.
    final inicio = widget.retraso.inMicroseconds / total.inMicroseconds;
    _avance = CurvedAnimation(
      parent: _control,
      curve: Interval(inicio, 1, curve: Movimiento.salida),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    if (Movimiento.animar(context)) {
      _control.forward();
    } else {
      _control.value = 1;
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _avance,
      child: widget.child,
      builder: (context, child) {
        final t = _avance.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.desde * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
