import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../widgets/avatar_usuario.dart';
import '../../../widgets/insignia_estado.dart';

/// Tarjeta de ejemplo del hero: una solicitud recibe tres postulantes, el
/// cliente elige a Carmen, el servicio se completa y la califica. Se repite
/// cada 12 segundos.
///
/// Es solo ilustración: no se puede tocar y los lectores de pantalla la
/// leen como una sola frase. Sin ciclos (pruebas o "reducir movimiento")
/// se queda quieta en el final, con Carmen elegida y calificada.
class TarjetaDemo extends StatefulWidget {
  const TarjetaDemo({super.key});

  @override
  State<TarjetaDemo> createState() => _TarjetaDemoState();
}

class _TarjetaDemoState extends State<TarjetaDemo> with SingleTickerProviderStateMixin {
  /// Momento que se muestra cuando no hay animación.
  static const _quieta = 0.9;

  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.ciclosActivos(context)) {
      if (!_control.isAnimating) _control.repeat();
    } else {
      _control
        ..stop()
        ..value = _quieta;
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ejemplo: tres trabajadoras se postulan a una solicitud, el cliente '
          'elige a Carmen y al terminar la califica con cinco estrellas.',
      excludeSemantics: true,
      child: IgnorePointer(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.texto.withValues(alpha: 0.22),
                blurRadius: 60,
                spreadRadius: -24,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _control,
            builder: (context, _) => _Contenido(t: _control.value),
          ),
        ),
      ),
    );
  }
}

/// Avance de 0 a 1 entre [desde] y [hasta] (fracciones del ciclo).
double _tramo(double t, double desde, double hasta, [Curve curva = Movimiento.salida]) {
  if (t <= desde) return 0;
  if (t >= hasta) return 1;
  return curva.transform((t - desde) / (hasta - desde));
}

/// Aparece en [entra], se va entre 0,92 y 0,96 (antes de reiniciar).
double _visible(double t, double entra, [double dura = 0.03]) =>
    _tramo(t, entra, entra + dura) * (1 - _tramo(t, 0.92, 0.96, Curves.ease));

class _Contenido extends StatelessWidget {
  const _Contenido({required this.t});

  final double t;

  static const _filas = [
    ('Yelitza Rojas', '4,6', '8 servicios', 0.075),
    ('Carmen Pérez', '4,9', '23 servicios', 0.158),
    ('Marisol Gómez', null, 'Nueva, sin reseñas', 0.242),
  ];

  @override
  Widget build(BuildContext context) {
    final postulantes = _filas.where((f) => t >= f.$4 + 0.015 && t < 0.94).length;

    final (estado, tono) = t < 0.43 || t >= 0.96
        ? ('Publicada', TonoInsignia.azul)
        : t < 0.655
            ? ('Asignada', TonoInsignia.verde)
            : ('Completada', TonoInsignia.ambar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu solicitud del sábado 21 de noviembre',
                    style: AppFonts.texto(
                      const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(child: Text('Postulantes', style: _estiloTitulo)),
                      const SizedBox(width: 10),
                      _Contador(postulantes),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _Cambiante(clave: estado, child: InsigniaEstado(estado, tono: tono)),
          ],
        ),
        const SizedBox(height: 12),
        for (final (i, fila) in _filas.indexed)
          _Fila(
            nombre: fila.$1,
            nota: fila.$2,
            detalle: fila.$3,
            visible: _visible(t, fila.$4),
            elegida: i == 1 ? _visible(t, 0.36) : null,
            marca: i == 1 ? _tramo(t, 0.38, 0.42) * (1 - _tramo(t, 0.92, 0.96)) : 0,
          ),
        const SizedBox(height: 12),
        _Calificacion(t: t),
        const SizedBox(height: 12),
        _Boton(t: t),
      ],
    );
  }
}

/// Función (y no constante) para que respete AppFonts.usarGoogleFonts.
TextStyle get _estiloTitulo => AppFonts.titulos(
  const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    height: 1.15,
    color: AppColors.texto,
  ),
);

/// Número de postulantes; cada número nuevo sube desde abajo.
class _Contador extends StatelessWidget {
  const _Contador(this.valor);

  final int valor;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: Movimiento.normal,
        switchInCurve: Movimiento.salida,
        switchOutCurve: Movimiento.salida,
        transitionBuilder: (child, animacion) {
          final entra = child.key == ValueKey(valor);
          return SlideTransition(
            position: Tween(
              begin: Offset(0, entra ? 1 : -1),
              end: Offset.zero,
            ).animate(animacion),
            child: child,
          );
        },
        child: Text(
          '$valor',
          key: ValueKey(valor),
          style: _estiloTitulo.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Cambia [child] con un fundido corto cuando cambia [clave].
class _Cambiante extends StatelessWidget {
  const _Cambiante({required this.clave, required this.child});

  final String clave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Movimiento.normal,
      switchInCurve: Movimiento.salida,
      layoutBuilder: (actual, anteriores) => Stack(
        alignment: Alignment.center,
        children: [...anteriores, ?actual],
      ),
      child: KeyedSubtree(key: ValueKey(clave), child: child),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.nombre,
    required this.nota,
    required this.detalle,
    required this.visible,
    required this.elegida,
    required this.marca,
  });

  final String nombre;

  /// Calificación ("4,9"); null si es nueva.
  final String? nota;
  final String detalle;
  final double visible;

  /// Qué tan resaltada está (solo la fila de Carmen).
  final double? elegida;

  /// Cuánto se ha dibujado el check (0 a 1).
  final double marca;

  @override
  Widget build(BuildContext context) {
    final resaltado = elegida ?? 0;
    final estiloDetalle = AppFonts.texto(
      const TextStyle(fontSize: 14, color: AppColors.textoSecundario),
    );

    return Opacity(
      opacity: visible,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - visible)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.superficie,
              AppColors.seleccionSuave,
              resaltado,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AvatarUsuario(nombre: nombre, tamano: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.texto(
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texto,
                        ),
                      ),
                    ),
                    if (nota == null)
                      Text(detalle, style: estiloDetalle)
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.star_rounded, size: 15, color: AppColors.ambar),
                            ),
                            TextSpan(text: ' $nota, $detalle'),
                          ],
                        ),
                        style: estiloDetalle,
                      ),
                  ],
                ),
              ),
              if (elegida != null) ...[
                const SizedBox(width: 8),
                SizedBox.square(
                  dimension: 22,
                  child: CustomPaint(painter: _Check(marca)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Check que se dibuja de izquierda a derecha.
class _Check extends CustomPainter {
  _Check(this.avance);

  final double avance;

  @override
  void paint(Canvas canvas, Size size) {
    if (avance <= 0) return;
    final escala = size.width / 24;
    final camino = Path()
      ..moveTo(5 * escala, 12.5 * escala)
      ..lineTo(9.5 * escala, 17 * escala)
      ..lineTo(19 * escala, 7.5 * escala);
    final pincel = Paint()
      ..color = AppColors.primario
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * escala
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final parcial = Path();
    final metricas = camino.computeMetrics().toList();
    final total = metricas.fold<double>(0, (suma, m) => suma + m.length);
    var falta = total * avance;
    for (final m in metricas) {
      final tramo = falta.clamp(0.0, m.length);
      parcial.addPath(m.extractPath(0, tramo), Offset.zero);
      falta -= tramo;
      if (falta <= 0) break;
    }
    canvas.drawPath(parcial, pincel);
  }

  @override
  bool shouldRepaint(_Check viejo) => viejo.avance != avance;
}

/// "Calificaste a Carmen" con las estrellas apareciendo una a una.
class _Calificacion extends StatelessWidget {
  const _Calificacion({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final fila = _visible(t, 0.67);
    return Opacity(
      opacity: fila,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - fila)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.insigniaAmbarFondo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Calificaste a Carmen',
                  style: AppFonts.texto(
                    const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texto,
                    ),
                  ),
                ),
              ),
              for (var i = 1; i <= 5; i++)
                Builder(
                  builder: (context) {
                    final estrella = _visible(t, 0.70 + i * 0.016, 0.025);
                    return Opacity(
                      opacity: estrella,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * estrella,
                        child: const Icon(Icons.star_rounded, size: 19, color: AppColors.ambar),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón falso: "Esperando postulantes" → "Elegir a Carmen" (se presiona)
/// → "Carmen confirmada".
class _Boton extends StatelessWidget {
  const _Boton({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final lleno = _tramo(t, 0.27, 0.29, Curves.ease) * (1 - _tramo(t, 0.96, 0.98, Curves.ease));
    // Se hunde un poco justo cuando "se toca".
    final hundido = _tramo(t, 0.41, 0.42, Curves.ease) * (1 - _tramo(t, 0.42, 0.435, Curves.ease));

    final etiqueta = t < 0.275 || t >= 0.96
        ? 'Esperando postulantes'
        : t < 0.42
            ? 'Elegir a Carmen'
            : 'Carmen confirmada';
    final colorTexto = Color.lerp(AppColors.textoSecundario, Colors.white, lleno)!;

    return Transform.scale(
      scale: 1 - 0.03 * hundido,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.arena, AppColors.primario, lleno),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _Cambiante(
          clave: etiqueta,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (etiqueta == 'Carmen confirmada') ...[
                Icon(Icons.check_rounded, size: 18, color: colorTexto),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  etiqueta,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.texto(
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorTexto),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
