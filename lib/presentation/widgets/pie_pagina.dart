import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/rutas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/utils/responsive.dart';
import 'enlace_subrayado.dart';
import 'logo_limpiaya.dart';

/// Pie de página de toda la web: logo, correo de contacto, enlaces
/// (términos, privacidad, sistema de diseño) y el crédito del proyecto.
///
/// Normalmente no se usa solo: [DesplazableConPie] lo pone al final de cada
/// pantalla y lo empuja al borde de abajo cuando el contenido es corto.
///
/// Con [compacto] queda en una sola franja (crédito, correo y enlaces), para
/// ponerlo debajo de un formulario, como en el inicio de sesión.
///
/// La landing usa su propio pie oscuro, más grande (PieLanding).
class PiePagina extends StatelessWidget {
  const PiePagina({super.key, this.onLogo, this.compacto = false});

  /// Qué hace el logo al tocarlo.
  final VoidCallback? onLogo;

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return compacto ? _franja(context) : _completo(context);
  }

  static TextStyle get _pequeno => AppFonts.texto(
        const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textoSecundario),
      );

  List<Widget> _enlacesLegales(BuildContext context, TextStyle estilo) => [
        EnlaceSubrayado(
          key: const Key('pie-terminos'),
          texto: 'Términos y condiciones',
          estilo: estilo,
          onTap: () => context.push(Rutas.terminos),
        ),
        EnlaceSubrayado(
          key: const Key('pie-privacidad'),
          texto: 'Política de privacidad',
          estilo: estilo,
          onTap: () => context.push(Rutas.privacidad),
        ),
      ];

  Widget _correo() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mail_outline_rounded, size: 17, color: AppColors.primario),
          const SizedBox(width: 8),
          Flexible(
            child: SelectableText(
              AppConstants.correoSoporte,
              style: AppFonts.texto(
                const TextStyle(fontSize: 15, color: AppColors.texto),
              ),
            ),
          ),
        ],
      );

  /// Versión de una franja, centrada, sin fondo propio.
  Widget _franja(BuildContext context) {
    return Container(
      key: const Key('pie-pagina'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 2,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'LimpiaYa, proyecto de Ingeniería de Software, UNIMET, 2026',
              textAlign: TextAlign.center,
              style: _pequeno,
            ),
          ),
          _correo(),
          ..._enlacesLegales(context, _pequeno),
        ],
      ),
    );
  }

  /// Pie de las pantallas: una franja baja con el logo y el correo a la
  /// izquierda, los enlaces a la derecha y el crédito en una línea abajo.
  Widget _completo(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final margen = Responsive.margen(context);
    final lateral = math.max(margen, (ancho - Responsive.anchoMaximo) / 2 + margen);

    final marca = Wrap(
      spacing: 24,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LogoLimpiaYa(tamano: 28, onTap: onLogo),
        _correo(),
      ],
    );

    final enlaces = Wrap(
      spacing: 24,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._enlacesLegales(context, _pequeno.copyWith(color: AppColors.texto)),
        EnlaceSubrayado(
          texto: 'Sistema de diseño',
          estilo: _pequeno.copyWith(color: AppColors.texto),
          onTap: () => context.push(Rutas.sistemaDiseno),
        ),
      ],
    );

    return Container(
      key: const Key('pie-pagina'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      padding: EdgeInsets.fromLTRB(lateral, movil ? 20 : 16, lateral, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap y no Row: si no caben en una línea (pantallas medianas o
          // teléfono), los enlaces bajan solos en vez de desbordarse.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 4,
            children: [marca, enlaces],
          ),
          const SizedBox(height: 6),
          Text(
            '© 2026 LimpiaYa · Proyecto de Ingeniería de Software, UNIMET · '
            'Hecho en Caracas, Venezuela',
            style: _pequeno.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
