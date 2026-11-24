import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/rutas.dart';
import '../../core/theme/app_colors.dart';
import 'boton_cerrar_sesion.dart';

/// Final del perfil: las acciones sobre la propia cuenta.
///
/// - HU-39 · Cambiar la contraseña.
/// - HU-42 · Desactivar la cuenta.
/// - Cerrar sesión (corrección del review: ya no está en la barra de arriba).
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
        const SizedBox(height: 8),
        TextButton.icon(
          key: const Key('ir-cambiar-contrasena'),
          onPressed: () => context.push(Rutas.cambiarContrasena),
          icon: const Icon(Icons.lock_outline_rounded, size: 20),
          label: const Text('Cambiar contraseña'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        TextButton.icon(
          key: const Key('ir-desactivar-cuenta'),
          onPressed: () => context.push(Rutas.desactivarCuenta),
          icon: const Icon(Icons.pause_circle_outline_rounded, size: 20),
          label: const Text('Desactivar mi cuenta'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cierra sesión si usas un teléfono o una computadora compartida.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: BotonCerrarSesion(),
        ),
      ],
    );
  }
}
