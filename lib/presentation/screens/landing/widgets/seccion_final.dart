import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/logo_limpiaya.dart';

/// Llamado final, en verde, con los dos caminos: cliente o trabajadora.
class SeccionFinal extends StatelessWidget {
  const SeccionFinal({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);

    return Container(
      width: double.infinity,
      color: AppColors.primario,
      padding: EdgeInsets.symmetric(vertical: movil ? 72 : 90, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              Text(
                'Tu casa limpia, en manos que conoces.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: movil ? 32 : 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comienza con una publicación. Decide solo cuando te sientas lista.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textoSobreOscuro),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  FilledButton(
                    style: AppTheme.botonAmbar,
                    onPressed: () => context.go(Rutas.registroCliente),
                    child: const Text('Necesito limpieza'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    onPressed: () => context.go(Rutas.registroTrabajadora),
                    child: const Text('Quiero trabajar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pie de página.
class PiePagina extends StatelessWidget {
  const PiePagina({super.key, required this.onLogo});

  final VoidCallback onLogo;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final margen = Responsive.margen(context);
    final lateral = math.max(margen, (ancho - Responsive.anchoMaximo) / 2 + margen);

    final logo = LogoLimpiaYa(tamano: 36, onTap: onLogo);
    final enlace = TextButton(
      style: TextButton.styleFrom(foregroundColor: AppColors.textoSecundario),
      onPressed: () => context.go(Rutas.sistemaDiseno),
      child: const Text('Sistema de diseño'),
    );
    final credito = Text(
      'Proyecto de Ingeniería de Software · UNIMET · 2026',
      textAlign: movil ? TextAlign.center : TextAlign.end,
      style: AppFonts.texto(
        const TextStyle(fontSize: 13, color: AppColors.textoSecundario),
      ),
    );

    return Container(
      width: double.infinity,
      color: AppColors.superficie,
      padding: EdgeInsets.symmetric(vertical: 38, horizontal: lateral),
      child: movil
          ? Column(
              children: [logo, const SizedBox(height: 12), enlace, const SizedBox(height: 8), credito],
            )
          : Row(
              children: [
                logo,
                const SizedBox(width: 40),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: enlace)),
                const SizedBox(width: 40),
                Flexible(child: credito),
              ],
            ),
    );
  }
}
