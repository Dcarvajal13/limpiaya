import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';

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
              const SizedBox(height: 20),
              // Los términos, a la vista desde la página principal.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Al registrarte aceptas los ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textoSobreOscuro,
                        ),
                  ),
                  InkWell(
                    key: const Key('landing-terminos'),
                    onTap: () => context.push(Rutas.terminos),
                    child: Text(
                      'Términos y condiciones',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                    ),
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
