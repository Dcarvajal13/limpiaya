import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'boton_cerrar_sesion.dart';

/// Final del perfil: "Cerrar sesión" (corrección del review: ya no está en
/// la barra de arriba, sino dentro del perfil).
class SeccionCuenta extends StatelessWidget {
  const SeccionCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Divider(color: AppColors.borde),
        const SizedBox(height: 16),
        Text('Cuenta', style: textos.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Cierra sesión si usas un teléfono o una computadora compartida.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: BotonCerrarSesion(),
        ),
      ],
    );
  }
}
