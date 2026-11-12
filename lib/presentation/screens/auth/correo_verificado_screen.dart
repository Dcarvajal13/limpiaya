import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/rutas.dart';
import '../../../core/router/verificacion_correo.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/verificacion_correo_provider.dart';
import 'widgets/plantilla_auth.dart';

/// HU-40 · Lo que ve quien abre el enlace de confirmación del correo.
///
/// - c1: "¡Tu correo quedó verificado!"
/// - c3: si el enlace ya se usó, "Tu correo ya está verificado".
class CorreoVerificadoScreen extends ConsumerWidget {
  const CorreoVerificadoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(enlaceCorreoProvider);
    final haySesion = ref.watch(authRepositoryProvider).usuarioActual != null;
    final textos = Theme.of(context).textTheme;

    final (icono, color, fondo, titulo, mensaje) = switch (estado) {
      EstadoEnlaceCorreo.yaUsado => (
          Icons.verified_outlined,
          AppColors.primario,
          AppColors.primarioClaro,
          'Tu correo ya está verificado',
          'Este enlace ya se usó. Inicia sesión para continuar. Si no puedes '
              'entrar, te ofreceremos un enlace nuevo.',
        ),
      EstadoEnlaceCorreo.error => (
          Icons.link_off_rounded,
          AppColors.error,
          AppColors.insigniaRojaFondo,
          'No pudimos verificar tu correo',
          'El enlace no es válido. Inicia sesión y te ofreceremos uno nuevo.',
        ),
      _ => (
          Icons.mark_email_read_outlined,
          AppColors.exito,
          AppColors.insigniaVerdeFondo,
          '¡Tu correo quedó verificado!',
          'Gracias por confirmarlo. Tu cuenta ya está activa.',
        ),
    };

    final continuarConSesion =
        haySesion && estado == EstadoEnlaceCorreo.verificado;

    void seguir() {
      ref.read(enlaceCorreoProvider.notifier).terminar();
      // Con sesión, el router lo lleva a su inicio (o a completar su
      // perfil). Sin sesión, al login.
      context.go(haySesion ? Rutas.inicio : Rutas.login);
    }

    return PlantillaAuth(
      titulo: 'Gracias por confiar en LimpiaYa.',
      texto: 'Un correo verificado nos ayuda a mantener segura la comunidad.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
            child: Icon(icono, size: 32, color: color),
          ),
          const SizedBox(height: 20),
          Text(titulo, style: textos.headlineLarge),
          const SizedBox(height: 8),
          Text(mensaje, style: textos.bodyLarge),
          const SizedBox(height: 28),
          FilledButton(
            key: const Key('seguir-correo-verificado'),
            onPressed: seguir,
            child: Text(continuarConSesion ? 'Continuar' : 'Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
