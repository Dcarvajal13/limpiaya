import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/logo_limpiaya.dart';
import 'comunes.dart';

/// Secciones a las que se puede saltar desde la barra de arriba.
enum DestinoLanding {
  comoFunciona('Cómo funciona'),
  confianza('Confianza'),
  precio('Precio'),
  preguntas('Preguntas');

  const DestinoLanding(this.etiqueta);
  final String etiqueta;
}

/// Barra fija de arriba para visitantes: logo, enlaces a las secciones
/// y los botones "Iniciar sesión" y "Registrarme" (HU-62, criterios 2 y 3).
class BarraVisitante extends StatelessWidget implements PreferredSizeWidget {
  const BarraVisitante({
    super.key,
    required this.alto,
    required this.onIrA,
    required this.onLogo,
  });

  final double alto;
  final ValueChanged<DestinoLanding> onIrA;
  final VoidCallback onLogo;

  @override
  Size get preferredSize => Size.fromHeight(alto);

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final movil = Responsive.esMovil(context);
    final margen = Responsive.margen(context);
    final conEnlaces = MedidasLanding.dosColumnas(context);
    final lateral = math.max(margen, (ancho - Responsive.anchoMaximo) / 2 + margen);

    final estiloCompacto = movil
        ? const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(48, 40)),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
          )
        : null;

    final botones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: estiloCompacto,
          onPressed: () => context.go(Rutas.login),
          child: const Text('Iniciar sesión'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: estiloCompacto,
          onPressed: () => context.go(Rutas.registro),
          child: const Text('Registrarme'),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fondo.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: alto,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: lateral),
            child: Row(
              children: [
                LogoLimpiaYa(
                  tamano: movil ? 36 : 40,
                  soloMarca: ancho < 460,
                  onTap: onLogo,
                ),
                const SizedBox(width: 16),
                if (conEnlaces)
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final destino in DestinoLanding.values)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textoSecundario,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                onPressed: () => onIrA(destino),
                                child: Text(destino.etiqueta),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Si la pantalla es muy angosta, los botones se achican
                // un poco en vez de salirse por el borde.
                Flexible(
                  flex: conEnlaces ? 2 : 1,
                  fit: conEnlaces ? FlexFit.loose : FlexFit.tight,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: botones,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
