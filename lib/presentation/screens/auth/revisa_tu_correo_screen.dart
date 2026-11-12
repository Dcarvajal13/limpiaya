import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/aviso_verificar_correo.dart';
import 'widgets/plantilla_auth.dart';

/// HU-40 · "Revisa tu correo": sale justo después de registrarse, mientras
/// la persona no haya abierto el enlace de confirmación.
///
/// El correo llega en la dirección: '/revisa-tu-correo?correo=...'.
class RevisaTuCorreoScreen extends StatelessWidget {
  const RevisaTuCorreoScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return PlantillaAuth(
      titulo: 'Ya casi terminas.',
      texto: 'Confirmar tu correo protege tu cuenta y te permite recuperarla '
          'si olvidas la contraseña.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarioClaro,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              size: 32,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 20),
          Text('Revisa tu correo', style: textos.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Tu cuenta está creada. Para empezar a usarla, abre el enlace '
            'que te enviamos.',
            style: textos.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (email.isNotEmpty)
            AvisoVerificarCorreo(
              email: email,
              titulo: 'Confirma tu correo',
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('ya-lo-confirme'),
            onPressed: () => context.go(Rutas.login),
            child: const Text('Ya lo confirmé, iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
