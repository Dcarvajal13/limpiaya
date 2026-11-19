import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/movimiento.dart';
import 'estrellas.dart';

/// Una reseña para mostrar en grande.
class Resena {
  const Resena(this.cita, this.nombre, this.detalle);

  final String cita;
  final String nombre;

  /// Por ejemplo "cliente en Chacao".
  final String detalle;
}

/// Reseñas de ejemplo de la landing y de las pantallas de acceso.
const resenasDeEjemplo = [
  Resena(
    'Pude leer sobre Carmen antes de elegirla. Llegó puntual y todo quedó impecable.',
    'María Alejandra',
    'cliente en Chacao',
  ),
  Resena(
    'Ahora consigo trabajos cerca y cada reseña me ayuda a crecer por mi cuenta.',
    'Carmen Pérez',
    'trabajadora en Baruta',
  ),
];

/// Reseñas grandes que se turnan solas: cada una se queda 7 segundos y
/// cambia con un fundido corto (sube, se enfoca y se desenfoca al salir).
/// Debajo, una barrita por reseña muestra cuánto falta para la siguiente.
///
/// Si los ciclos están apagados (pruebas o "reducir movimiento"), se ve
/// solo la primera reseña, quieta.
class ResenasRotativas extends StatefulWidget {
  const ResenasRotativas({
    super.key,
    this.resenas = resenasDeEjemplo,
    this.sobreOscuro = false,
    this.tamanoCita = 46,
  });

  final List<Resena> resenas;
  final bool sobreOscuro;
  final double tamanoCita;

  @override
  State<ResenasRotativas> createState() => _ResenasRotativasState();
}

class _ResenasRotativasState extends State<ResenasRotativas>
    with SingleTickerProviderStateMixin {
  static const _porResena = Duration(seconds: 7);

  /// Parte de cada turno que dura la entrada y la salida (0,1 = 700 ms).
  static const _cambio = 0.1;

  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: _porResena * widget.resenas.length,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.ciclosActivos(context)) {
      if (!_control.isAnimating) _control.repeat();
    } else {
      _control
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enCiclo = _control.isAnimating;

    return AnimatedBuilder(
      animation: _control,
      builder: (context, _) {
        final n = widget.resenas.length;
        final posicion = _control.value * n;
        final activa = posicion.floor() % n;
        final avance = enCiclo ? posicion - posicion.floor() : 1.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Todas las reseñas ocupan el mismo lugar; el bloque toma el
            // alto de la más larga y así nada salta al cambiar.
            Stack(
              children: [
                for (var i = 0; i < n; i++)
                  _capa(i, activa: activa, avance: avance, enCiclo: enCiclo),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                for (var i = 0; i < n; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _Barrita(
                    llenado: i == activa ? (enCiclo ? avance : 1.0) : 0.0,
                    sobreOscuro: widget.sobreOscuro,
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _capa(int i, {required int activa, required double avance, required bool enCiclo}) {
    // Qué tan visible está: 0 fuera, 1 del todo.
    var visible = i == activa ? 1.0 : 0.0;
    var saliendo = false;
    if (i == activa && enCiclo) {
      if (avance < _cambio) {
        visible = Movimiento.salida.transform(avance / _cambio);
      } else if (avance > 1 - _cambio) {
        visible = 1 - Curves.ease.transform((avance - (1 - _cambio)) / _cambio);
        saliendo = true;
      }
    }

    Widget cita = _Cita(
      resena: widget.resenas[i],
      sobreOscuro: widget.sobreOscuro,
      tamano: widget.tamanoCita,
    );
    if (visible > 0 && visible < 1) {
      final borroso = 6 * (1 - visible);
      cita = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: borroso, sigmaY: borroso),
        child: cita,
      );
    }

    final desplazamiento = saliendo ? -10 * (1 - visible) : 12 * (1 - visible);
    return IgnorePointer(
      ignoring: visible == 0,
      child: ExcludeSemantics(
        excluding: visible == 0,
        child: Opacity(
          opacity: visible,
          child: Transform.translate(offset: Offset(0, desplazamiento), child: cita),
        ),
      ),
    );
  }
}

class _Cita extends StatelessWidget {
  const _Cita({required this.resena, required this.sobreOscuro, required this.tamano});

  final Resena resena;
  final bool sobreOscuro;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final colorCita = sobreOscuro ? Colors.white : AppColors.texto;
    final colorDetalle = sobreOscuro ? AppColors.textoSobreOscuro : AppColors.textoSecundario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Estrellas(valor: 5, tamano: 20),
        const SizedBox(height: 16),
        Text(
          '“${resena.cita}”',
          style: AppFonts.titulos(
            TextStyle(
              fontSize: tamano,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              height: 1.14,
              letterSpacing: -0.01 * tamano,
              color: colorCita,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: resena.nombre,
                style: TextStyle(fontWeight: FontWeight.w600, color: colorCita),
              ),
              TextSpan(text: ', ${resena.detalle}'),
            ],
          ),
          style: AppFonts.texto(TextStyle(fontSize: 16, color: colorDetalle)),
        ),
      ],
    );
  }
}

/// Barrita de progreso de cada reseña.
class _Barrita extends StatelessWidget {
  const _Barrita({required this.llenado, required this.sobreOscuro});

  final double llenado;
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    final fondo = sobreOscuro ? Colors.white.withValues(alpha: 0.25) : AppColors.borde;
    final relleno = sobreOscuro ? Colors.white : AppColors.primario;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 44,
        height: 4,
        child: ColoredBox(
          color: fondo,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: llenado.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: relleno),
            ),
          ),
        ),
      ),
    );
  }
}
