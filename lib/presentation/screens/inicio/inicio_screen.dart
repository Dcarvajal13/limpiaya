import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sesion_provider.dart';
import '../../widgets/boton_cerrar_sesion.dart';
import '../../widgets/logo_limpiaya.dart';

/// Espera mientras se carga el rol de quien inició sesión.
///
/// Apenas se sabe el rol, el router manda a cada quien a su inicio
/// (ver core/router/redireccion.dart). Si no se pudo cargar, se muestra
/// un mensaje con la opción de reintentar o de cerrar sesión.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final textos = Theme.of(context).textTheme;
    final fallo = !sesion.isLoading && sesion.value == null;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoLimpiaYa(),
              const SizedBox(height: 32),
              if (!fallo)
                const CircularProgressIndicator()
              else ...[
                Text(
                  'No pudimos cargar tu cuenta',
                  style: textos.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexión e intenta de nuevo.',
                  style: textos.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => ref.invalidate(sesionProvider),
                  child: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                const BotonCerrarSesion(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
