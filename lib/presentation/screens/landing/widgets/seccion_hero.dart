import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/aparecer.dart';
import '../../../widgets/contenido_centrado.dart';
import '../../../widgets/resenas_rotativas.dart';
import 'comunes.dart';
import 'tarjeta_demo.dart';

enum _Publico { cliente, trabajadora }

/// Primera parte de la landing: reseñas reales que se turnan, el selector
/// "Necesito limpieza / Quiero trabajar" con su mensaje, y a la derecha una
/// foto con la tarjeta de ejemplo que se anima sola.
class SeccionHero extends StatefulWidget {
  const SeccionHero({super.key});

  @override
  State<SeccionHero> createState() => _SeccionHeroState();
}

class _SeccionHeroState extends State<SeccionHero> {
  var _publico = _Publico.cliente;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final dosColumnas = MedidasLanding.dosColumnas(context);

    final texto = _TextoHero(
      publico: _publico,
      onCambiar: (p) => setState(() => _publico = p),
    );
    const derecha = Aparecer(
      retraso: Duration(milliseconds: 160),
      desde: 24,
      child: _FotoConDemo(),
    );

    return ContenidoCentrado(
      child: Padding(
        padding: EdgeInsets.only(top: movil ? 36 : 64, bottom: movil ? 56 : 96),
        child: dosColumnas
            ? Row(
                children: [
                  Expanded(flex: 56, child: texto),
                  const SizedBox(width: 64),
                  Expanded(
                    flex: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: derecha,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  texto,
                  const SizedBox(height: 48),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: derecha,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TextoHero extends StatelessWidget {
  const _TextoHero({required this.publico, required this.onCambiar});

  final _Publico publico;
  final ValueChanged<_Publico> onCambiar;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final dosColumnas = MedidasLanding.dosColumnas(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Aparecer(
          child: ResenasRotativas(tamanoCita: movil ? 30 : (dosColumnas ? 46 : 40)),
        ),
        const SizedBox(height: 40),
        Aparecer(
          retraso: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.only(top: 30),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borde)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Selector(publico: publico, onCambiar: onCambiar, anchoCompleto: movil),
                const SizedBox(height: 22),
                _Mensaje(publico: publico),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Título, texto y botón según a quién le hablamos. Al cambiar de opción
/// el texto viejo se desvanece y el nuevo sube un poco.
class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.publico});

  final _Publico publico;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final esCliente = publico == _Publico.cliente;

    final contenido = Column(
      key: ValueKey(publico),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            esCliente
                ? 'Elige con calma a quien entra a tu casa.'
                : 'Tu trabajo habla por ti.',
            style: textos.displayLarge?.copyWith(
              fontSize: movil ? 32 : 42,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            esCliente
                ? 'Publica la fecha y el pago. Trabajadoras verificadas de tu '
                    'zona se postulan, y comparas su historia y sus reseñas '
                    'antes de decidir.'
                : 'Más clientes sin depender del boca a boca. Tu reputación '
                    'crece con cada servicio y tú decides tus zonas y tu tarifa.',
            style: textos.bodyLarge?.copyWith(fontSize: movil ? 16.5 : 18),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 22,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              onPressed: () => context.go(
                esCliente ? Rutas.registroCliente : Rutas.registroTrabajadora,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      esCliente ? 'Publicar mi primera solicitud' : 'Crear mi perfil gratis',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            LineaConIcono(
              icono: Icons.verified_user_outlined,
              texto: 'Identidad verificada',
              estilo: textos.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.texto,
              ),
              espacio: 8,
            ),
          ],
        ),
      ],
    );

    return AnimatedSwitcher(
      duration: Movimiento.animar(context) ? Movimiento.normal : Duration.zero,
      switchInCurve: Movimiento.salida,
      switchOutCurve: Curves.ease,
      layoutBuilder: (actual, anteriores) => Stack(
        alignment: Alignment.topLeft,
        children: [...anteriores, ?actual],
      ),
      transitionBuilder: (child, animacion) => FadeTransition(
        opacity: animacion,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(animacion),
          child: child,
        ),
      ),
      child: contenido,
    );
  }
}

/// Selector de dos opciones. La pastilla blanca se desliza a la opción
/// elegida.
class _Selector extends StatelessWidget {
  const _Selector({
    required this.publico,
    required this.onCambiar,
    required this.anchoCompleto,
  });

  final _Publico publico;
  final ValueChanged<_Publico> onCambiar;
  final bool anchoCompleto;

  @override
  Widget build(BuildContext context) {
    final animar = Movimiento.animar(context);

    Widget opcion(_Publico valor, String texto) {
      final activa = publico == valor;
      return Expanded(
        child: Semantics(
          selected: activa,
          button: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => onCambiar(valor),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: animar ? Movimiento.rapido : Duration.zero,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontSize: 15,
                            color: activa ? AppColors.texto : AppColors.textoSecundario,
                          ),
                      child: Text(texto, textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: anchoCompleto ? double.infinity : 380,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.arena,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                alignment: publico == _Publico.cliente
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: animar ? Movimiento.normal : Duration.zero,
                curve: Movimiento.desplazamiento,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.texto.withValues(alpha: 0.18),
                          blurRadius: 8,
                          spreadRadius: -2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  opcion(_Publico.cliente, 'Necesito limpieza'),
                  opcion(_Publico.trabajadora, 'Quiero trabajar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto de Carmen con la tarjeta de ejemplo montada encima de su parte
/// baja. La foto entra con un acercamiento suave.
class _FotoConDemo extends StatelessWidget {
  const _FotoConDemo();

  @override
  Widget build(BuildContext context) {
    final animar = Movimiento.animar(context);

    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final angosto = ancho < 420;
        final margenFoto = angosto ? 24.0 : 48.0;
        final altoFoto = (ancho - margenFoto) * (angosto ? 1.0 : 1.25);
        // Cuánto de la foto queda visible encima de la tarjeta.
        final arriba = math.max(altoFoto * (angosto ? 0.55 : 0.52), 160.0);

        return Stack(
          children: [
            Positioned(
              top: 0,
              left: margenFoto,
              right: 0,
              height: altoFoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: animar ? 1.08 : 1.0, end: 1.0),
                  duration: animar ? const Duration(milliseconds: 1100) : Duration.zero,
                  curve: Movimiento.salida,
                  builder: (context, escala, child) =>
                      Transform.scale(scale: escala, child: child),
                  child: Image.asset(
                    'assets/images/trabajadora.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.16, 0),
                    semanticLabel: 'Carmen limpiando una casa',
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.arenaOscura),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: arriba, right: angosto ? 0 : 24),
              child: const TarjetaDemo(),
            ),
          ],
        );
      },
    );
  }
}
