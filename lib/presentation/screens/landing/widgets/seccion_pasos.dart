import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// "Cómo funciona": los cinco pasos del servicio (HU-62, criterio 1).
///
/// Una barra arriba se llena en 10 segundos y los pasos se van marcando
/// uno tras otro, como si un servicio pasara frente a ti. Sin ciclos
/// (pruebas o "reducir movimiento") todos se ven marcados.
class SeccionPasos extends StatefulWidget {
  const SeccionPasos({super.key});

  @override
  State<SeccionPasos> createState() => _SeccionPasosState();
}

class _SeccionPasosState extends State<SeccionPasos> with SingleTickerProviderStateMixin {
  static const _pasos = [
    ('Publica', 'Cuéntanos cuándo, dónde y cuánto pagas. Tu dirección queda privada.'),
    ('Se postulan', 'Trabajadoras verificadas cercanas te cuentan por qué quieren ayudarte.'),
    ('Elige', 'Compara experiencia, reseñas e historia antes de decidir.'),
    ('Servicio', 'Coordinan por el chat de LimpiaYa, sin compartir teléfonos.'),
    ('Califican', 'Al terminar, ambas se califican y la comunidad se vuelve más confiable.'),
  ];

  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.ciclosActivos(context)) {
      if (!_control.isAnimating) _control.repeat();
    } else {
      _control
        ..stop()
        ..value = 0.9;
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MedidasLanding.dosColumnas(context);

    return FranjaLanding(
      color: AppColors.arena,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            antetitulo: 'Así funciona',
            titulo: 'Tú publicas. Tú comparas. Tú eliges.',
            texto: 'Sin llamadas incómodas ni datos personales expuestos.',
          ),
          AnimatedBuilder(
            animation: _control,
            builder: (context, _) {
              final t = _control.value;
              // La barra se llena hasta el 96 % del ciclo y se vacía rápido.
              final barra = t < 0.96 ? t / 0.96 : 1 - (t - 0.96) / 0.04;
              // Cada paso se marca un poco después del anterior y todos se
              // desmarcan juntos al final.
              bool marcado(int i) => t >= i * 0.18 + 0.02 && t < 0.97;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 3,
                      child: ColoredBox(
                        color: AppColors.arenaOscura,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: barra.clamp(0.0, 1.0),
                            heightFactor: 1,
                            child: const ColoredBox(color: AppColors.primario),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Rejilla(
                    columnas: dosColumnas ? 5 : 1,
                    espacio: dosColumnas ? 28 : 4,
                    children: [
                      for (final (i, (titulo, texto)) in _pasos.indexed)
                        _Paso(
                          numero: i + 1,
                          titulo: titulo,
                          texto: texto,
                          marcado: marcado(i),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.texto,
    required this.marcado,
  });

  final int numero;
  final String titulo;
  final String texto;
  final bool marcado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final animar = Movimiento.animar(context);
    final duracion = animar ? Movimiento.normal : Duration.zero;

    final circulo = AnimatedScale(
      scale: marcado ? 1 : 0.92,
      duration: duracion,
      curve: Movimiento.salida,
      child: AnimatedContainer(
        duration: duracion,
        curve: Movimiento.salida,
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: marcado ? AppColors.primario : AppColors.superficie,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$numero',
          style: AppFonts.titulos(
            TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w500,
              color: marcado ? Colors.white : AppColors.primario,
            ),
          ),
        ),
      ),
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: duracion,
          style: textos.headlineSmall!.copyWith(
            fontSize: movil ? 22 : 24,
            color: marcado ? AppColors.texto : AppColors.textoSecundario,
          ),
          child: Text(titulo),
        ),
        const SizedBox(height: 8),
        Text(texto, style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: MedidasLanding.dosColumnas(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [circulo, const SizedBox(height: 18), cuerpo],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [circulo, const SizedBox(width: 16), Expanded(child: cuerpo)],
            ),
    );
  }
}
