import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// Preguntas frecuentes, que se abren y cierran.
class SeccionPreguntas extends StatelessWidget {
  const SeccionPreguntas({super.key});

  static const _preguntas = [
    (
      '¿Cómo sé que la trabajadora es quien dice ser?',
      'Cada trabajadora debe completar una verificación de identidad con su '
          'cédula y una selfie antes de poder postularse.',
    ),
    (
      '¿En qué zonas está disponible?',
      'En zonas de Baruta, Chacao, El Hatillo, Sucre y Libertador.',
    ),
    (
      '¿Cómo se paga el servicio?',
      'Directamente a la trabajadora por Pago Móvil, transferencia o efectivo, '
          'en dólares o bolívares.',
    ),
    (
      '¿Qué pasa si una trabajadora no tiene reseñas?',
      'Verás la etiqueta “Nueva en la plataforma” y podrás valorar su '
          'experiencia y su presentación.',
    ),
    (
      '¿Necesito descargar una app?',
      'No. LimpiaYa funciona desde tu navegador, en computadora o teléfono.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    const borde = Border(bottom: BorderSide(color: AppColors.borde));
    final estiloPregunta = AppFonts.titulos(
      TextStyle(
        fontSize: Responsive.esMovil(context) ? 17 : 18,
        fontWeight: FontWeight.w700,
        color: AppColors.texto,
      ),
    );

    return FranjaLanding(
      anchoMaximo: 850 + 2 * Responsive.margen(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            antetitulo: 'Preguntas frecuentes',
            titulo: 'Lo importante, sin vueltas.',
          ),
          for (var i = 0; i < _preguntas.length; i++)
            ExpansionTile(
              initiallyExpanded: i == 0,
              shape: borde,
              collapsedShape: borde,
              tilePadding: const EdgeInsets.symmetric(vertical: 8),
              childrenPadding: const EdgeInsets.only(bottom: 20, right: 40),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: AppColors.primario,
              collapsedIconColor: AppColors.texto,
              title: Text(_preguntas[i].$1, style: estiloPregunta),
              children: [
                Text(
                  _preguntas[i].$2,
                  style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
