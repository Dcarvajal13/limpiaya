import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/avatar_usuario.dart';
import '../../../widgets/contenido_centrado.dart';
import '../../../widgets/insignia_estado.dart';
import '../../../widgets/logo_limpiaya.dart';
import 'comunes.dart';

enum _Publico { cliente, trabajadora }

/// Primera parte de la landing: qué es LimpiaYa, con un selector
/// "Necesito limpieza / Quiero trabajar" y un teléfono de ejemplo.
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
    const telefono = _TelefonoConFondo();

    return ContenidoCentrado(
      vertical: 0,
      child: Padding(
        padding: EdgeInsets.only(top: movil ? 40 : 80, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dosColumnas)
              Row(
                children: [
                  Expanded(flex: 105, child: texto),
                  const SizedBox(width: 80),
                  const Expanded(flex: 95, child: telefono),
                ],
              )
            else ...[
              texto,
              const SizedBox(height: 48),
              telefono,
            ],
            SizedBox(height: dosColumnas ? 80 : 48),
            const _FranjaConfianza(),
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
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final esCliente = publico == _Publico.cliente;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Selector(publico: publico, onCambiar: onCambiar, anchoCompleto: movil),
        const SizedBox(height: 32),
        const Antetitulo('Limpieza de confianza en Caracas'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            esCliente
                ? 'Elige con calma a quien entra a tu casa.'
                : 'Tu trabajo habla por ti.',
            style: textos.displayLarge?.copyWith(fontSize: movil ? 40 : 64),
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 630),
          child: Text(
            esCliente
                ? 'Publica la fecha y el pago. Trabajadoras verificadas de tu '
                    'zona se postulan, y comparas su historia y sus reseñas '
                    'antes de decidir.'
                : 'Más clientes sin depender del boca a boca. Tu reputación '
                    'crece con cada servicio y tú decides tus zonas y tu tarifa.',
            style: textos.bodyLarge?.copyWith(fontSize: movil ? 17 : 20),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: AppTheme.botonAmbar,
          onPressed: () => context.go(
            esCliente ? Rutas.registroCliente : Rutas.registroTrabajadora,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(esCliente ? 'Crear mi cuenta' : 'Quiero trabajar'),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// Selector de dos opciones con fondo arena (como en el prototipo).
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
    Widget opcion(_Publico valor, String texto) {
      final activa = publico == valor;
      final boton = Semantics(
        selected: activa,
        button: true,
        child: Material(
          color: activa ? AppColors.superficie : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onCambiar(valor),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: activa ? AppColors.primario : AppColors.texto,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return anchoCompleto ? Expanded(child: boton) : Flexible(child: boton);
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.arena,
        borderRadius: BorderRadius.circular(14),
      ),
      // IntrinsicHeight: si un texto ocupa dos líneas, ambas opciones
      // quedan del mismo alto.
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: anchoCompleto ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            opcion(_Publico.cliente, 'Necesito limpieza'),
            opcion(_Publico.trabajadora, 'Quiero trabajar'),
          ],
        ),
      ),
    );
  }
}

/// Mancha verde clara con el teléfono de ejemplo encima.
class _TelefonoConFondo extends StatelessWidget {
  const _TelefonoConFondo();

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final conNota = MedidasLanding.dosColumnas(context);

    return LayoutBuilder(
      builder: (context, restricciones) {
        final anchoTelefono =
            math.min(movil ? 290.0 : 330.0, restricciones.maxWidth - 32);

        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: movil ? 460 : 520),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _Mancha()),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _Telefono(ancho: anchoTelefono),
              ),
              if (conNota)
                Positioned(
                  right: 0,
                  top: 20,
                  child: Transform.rotate(
                    angle: 4 * math.pi / 180,
                    child: Text(
                      'Personas reales.\nDecisiones informadas.',
                      style: AppFonts.titulos(
                        const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primario,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Forma orgánica (no un círculo perfecto) detrás del teléfono.
class _Mancha extends StatelessWidget {
  const _Mancha();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarioClaro,
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(w * 0.48, h * 0.50),
              topRight: Radius.elliptical(w * 0.52, h * 0.40),
              bottomRight: Radius.elliptical(w * 0.43, h * 0.60),
              bottomLeft: Radius.elliptical(w * 0.57, h * 0.50),
            ),
          ),
        );
      },
    );
  }
}

/// Maqueta de la pantalla "postulantes" dentro de un teléfono.
class _Telefono extends StatelessWidget {
  const _Telefono({required this.ancho});

  final double ancho;

  static const _postulantes = [
    ('Carmen Pérez', '4,9', '23 servicios'),
    ('Yelitza Rojas', '4,6', '8 servicios'),
    ('Marisol Gómez', 'Nueva', 'Sin reseñas'),
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    return Transform.rotate(
      angle: 1.5 * math.pi / 180,
      child: Container(
        width: ancho,
        padding: EdgeInsets.all(movil ? 17 : 22),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.primarioOscuro, width: 8),
          boxShadow: const [
            BoxShadow(color: AppColors.arena, offset: Offset(12, 16)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: LogoLimpiaYa(tamano: 28),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                InsigniaEstado('3 postulantes', tono: TonoInsignia.azul),
              ],
            ),
            const SizedBox(height: 20),
            Text('Sábado 17 oct.', style: textos.titleLarge),
            const SizedBox(height: 4),
            Text('Limpieza general · Chacao', style: textos.bodySmall?.copyWith(fontSize: 13)),
            const SizedBox(height: 7),
            for (var i = 0; i < _postulantes.length; i++)
              _FilaPostulante(
                nombre: _postulantes[i].$1,
                calificacion: _postulantes[i].$2,
                servicios: _postulantes[i].$3,
                elegida: i == 0,
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(Rutas.registroCliente),
              child: const Text('Elegir a Carmen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaPostulante extends StatelessWidget {
  const _FilaPostulante({
    required this.nombre,
    required this.calificacion,
    required this.servicios,
    required this.elegida,
  });

  final String nombre;
  final String calificacion;
  final String servicios;
  final bool elegida;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: elegida ? AppColors.seleccionSuave : AppColors.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: elegida ? AppColors.primario : AppColors.borde),
      ),
      child: Row(
        children: [
          AvatarUsuario(nombre: nombre, tamano: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: textos.titleSmall?.copyWith(fontSize: 13)),
                Text.rich(
                  TextSpan(
                    children: [
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.star_rounded, size: 13, color: AppColors.ambar),
                      ),
                      TextSpan(text: ' $calificacion · $servicios'),
                    ],
                  ),
                  style: textos.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          if (elegida) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_rounded, size: 18, color: AppColors.primario),
          ],
        ],
      ),
    );
  }
}

/// Las tres promesas debajo del hero.
class _FranjaConfianza extends StatelessWidget {
  const _FranjaConfianza();

  static const _puntos = [
    (Icons.verified_user_outlined, 'Identidad verificada'),
    (Icons.star_outline_rounded, 'Reseñas de ambos lados'),
    (Icons.payments_outlined, 'Precio acordado antes del servicio'),
  ];

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final movil = Responsive.esMovil(context);

    final puntos = [
      for (final (icono, texto) in _puntos)
        LineaConIcono(icono: icono, texto: texto, estilo: estilo, espacio: 9),
    ];

    return Container(
      padding: const EdgeInsets.only(top: 30),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: movil
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in puntos) ...[p, const SizedBox(height: 16)],
              ],
            )
          : Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 24,
              runSpacing: 16,
              children: puntos,
            ),
    );
  }
}
