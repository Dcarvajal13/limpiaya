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

  static TextStyle get _enlace => AppFonts.texto(
        const TextStyle(fontSize: 15, color: AppColors.texto),
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

  Widget _completo(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final margen = Responsive.margen(context);
    final lateral = math.max(margen, (ancho - Responsive.anchoMaximo) / 2 + margen);

    final marca = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogoLimpiaYa(tamano: 34, onTap: onLogo),
          const SizedBox(height: 12),
          Text(
            'Limpieza del hogar con trabajadoras verificadas en Caracas.',
            style: _pequeno.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 12),
          _correo(),
        ],
      ),
    );

    final legal = _Columna(
      titulo: 'Legal',
      enlaces: _enlacesLegales(context, _enlace),
    );

    final proyecto = _Columna(
      titulo: 'Proyecto',
      enlaces: [
        EnlaceSubrayado(
          texto: 'Sistema de diseño',
          estilo: _enlace,
          onTap: () => context.push(Rutas.sistemaDiseno),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              'Ingeniería de Software, UNIMET',
              style: _enlace.copyWith(color: AppColors.textoSecundario),
            ),
          ),
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
      padding: EdgeInsets.fromLTRB(lateral, movil ? 32 : 44, lateral, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (movil)
            Wrap(
              spacing: 40,
              runSpacing: 28,
              children: [marca, legal, proyecto],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Align(alignment: Alignment.topLeft, child: marca)),
                const SizedBox(width: 24),
                Expanded(child: legal),
                const SizedBox(width: 24),
                Expanded(child: proyecto),
              ],
            ),
          SizedBox(height: movil ? 24 : 36),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              '© 2026 LimpiaYa, hecho en Caracas, Venezuela',
              textAlign: movil ? TextAlign.start : TextAlign.center,
              style: _pequeno,
            ),
          ),
        ],
      ),
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({required this.titulo, required this.enlaces});

  final String titulo;
  final List<Widget> enlaces;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            titulo,
            style: AppFonts.texto(
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...enlaces,
      ],
    );
  }
}
