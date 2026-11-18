import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// Bloque para trabajadoras: por qué les conviene y que es gratis para ellas.
class SeccionTrabajadoras extends StatelessWidget {
  const SeccionTrabajadoras({super.key});

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MedidasLanding.dosColumnas(context);

    const imagen = _FotoConAvisos();
    const texto = _TextoTrabajadoras();

    return FranjaLanding(
      child: dosColumnas
          ? const Row(
              children: [
                Expanded(flex: 11, child: imagen),
                SizedBox(width: 80),
                Expanded(flex: 10, child: texto),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [imagen, SizedBox(height: 40), texto],
            ),
    );
  }
}

/// Foto de una trabajadora con los avisos que recibe en LimpiaYa, que se
/// turnan cada 3 segundos (ciclo de 9). Sin ciclos se ve solo el primero.
class _FotoConAvisos extends StatefulWidget {
  const _FotoConAvisos();

  @override
  State<_FotoConAvisos> createState() => _FotoConAvisosState();
}

class _FotoConAvisosState extends State<_FotoConAvisos> with SingleTickerProviderStateMixin {
  static const _foto = 'assets/images/trabajadora.jpg';

  static const _avisos = [
    (
      Icons.location_on_outlined,
      'Nueva solicitud en Altamira',
      'Sábado 8:00 a. m., recibes \$30',
      AppColors.insigniaAzulFondo,
      AppColors.primario,
    ),
    (
      Icons.check_rounded,
      'María Alejandra te eligió',
      'Limpieza profunda el jueves 26',
      AppColors.insigniaVerdeFondo,
      AppColors.exito,
    ),
    (
      Icons.star_rounded,
      'Recibiste una reseña de 5 estrellas',
      '“Llegó puntual y todo quedó impecable.”',
      AppColors.insigniaAmbarFondo,
      AppColors.aviso,
    ),
  ];

  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimiento.ciclosActivos(context)) {
      if (!_control.isAnimating) _control.repeat();
    } else {
      _control
        ..stop()
        ..value = 0.15;
    }
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  /// Visibilidad del aviso [i] (0 a 1) y si va entrando o saliendo.
  (double, bool) _estado(int i) {
    // Cada aviso usa su propio tercio del ciclo.
    final local = (_control.value - i / 3) % 1;
    if (local < 0.05) return (Movimiento.salida.transform(local / 0.05), false);
    if (local < 0.29) return (1.0, false);
    if (local < 0.333) return (1 - Curves.ease.transform((local - 0.29) / 0.043), true);
    return (0.0, false);
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);

    return AspectRatio(
      aspectRatio: movil ? 4 / 4.2 : 5 / 4,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                _foto,
                fit: BoxFit.cover,
                alignment: const Alignment(0.28, 0),
                semanticLabel: 'Una trabajadora de LimpiaYa en una casa',
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.arenaOscura),
              ),
            ),
          ),
          Positioned(
            left: movil ? 12 : 24,
            right: movil ? 12 : 96,
            top: movil ? 12 : 24,
            child: Semantics(
              label: 'Avisos que recibe una trabajadora: nuevas solicitudes, '
                  'cuando un cliente la elige y sus reseñas.',
              excludeSemantics: true,
              child: AnimatedBuilder(
                animation: _control,
                builder: (context, _) => Stack(
                  children: [
                    for (final (i, aviso) in _avisos.indexed)
                      Builder(
                        builder: (context) {
                          final (visible, saliendo) = _estado(i);
                          final dy = saliendo ? 10 * (1 - visible) : -18 * (1 - visible);
                          return Opacity(
                            opacity: visible,
                            child: Transform.translate(
                              offset: Offset(0, dy),
                              child: Transform.scale(
                                scale: 0.98 + 0.02 * visible,
                                child: _Aviso(
                                  icono: aviso.$1,
                                  titulo: aviso.$2,
                                  texto: aviso.$3,
                                  fondoIcono: aviso.$4,
                                  colorIcono: aviso.$5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.fondoIcono,
    required this.colorIcono,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Color fondoIcono;
  final Color colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.texto.withValues(alpha: 0.25),
            blurRadius: 50,
            spreadRadius: -24,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: fondoIcono,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, size: 21, color: colorIcono),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppFonts.texto(
                    const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texto,
                    ),
                  ),
                ),
                Text(
                  texto,
                  style: AppFonts.texto(
                    const TextStyle(fontSize: 14, color: AppColors.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextoTrabajadoras extends StatelessWidget {
  const _TextoTrabajadoras();

  static const _beneficios = [
    'Más clientes cerca de ti',
    'Tu reputación digital crece contigo',
    'Tú controlas zonas, servicios y tarifa',
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final estiloBeneficio = AppFonts.texto(
      TextStyle(
        fontSize: movil ? 16.5 : 18,
        fontWeight: FontWeight.w600,
        color: AppColors.texto,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Antetitulo('Para trabajadoras'),
        const SizedBox(height: 14),
        Text(
          'Tu experiencia merece abrirte puertas.',
          style: textos.displayMedium?.copyWith(
            fontSize: movil ? 32 : 46,
            height: 1.06,
          ),
        ),
        const SizedBox(height: 26),
        for (final beneficio in _beneficios) ...[
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.insigniaVerdeFondo,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 17, color: AppColors.exito),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(beneficio, style: estiloBeneficio)),
            ],
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 10),
        Text(
          'Usar LimpiaYa es gratis para las trabajadoras.',
          style: textos.bodyLarge?.copyWith(color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 22),
        OutlinedButton(
          onPressed: () => context.go(Rutas.registroTrabajadora),
          child: const Text('Crear mi perfil'),
        ),
      ],
    );
  }
}
