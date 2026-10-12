import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/router/rutas.dart';

/// HU-03 · Cerrar sesión.
///
/// Botón para la barra de arriba de las pantallas con sesión:
///   AppBar(actions: const [BotonCerrarSesion()])
///
/// Al cerrar sesión lleva a la página de inicio (landing). Después de eso,
/// si alguien intenta abrir una pantalla con sesión (por ejemplo '/cliente'),
/// el router lo manda al login.
class BotonCerrarSesion extends ConsumerStatefulWidget {
  const BotonCerrarSesion({super.key});

  @override
  ConsumerState<BotonCerrarSesion> createState() => _BotonCerrarSesionState();
}

class _BotonCerrarSesionState extends ConsumerState<BotonCerrarSesion> {
  bool _cerrando = false;

  Future<void> _cerrarSesion() async {
    // Se guardan antes de esperar: al cerrar sesión esta pantalla
    // desaparece y ya no se podrían pedir.
    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _cerrando = true);
    try {
      await ref.read(authRepositoryProvider).cerrarSesion();
      router.go(Rutas.landing);
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
      if (mounted) setState(() => _cerrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
        onPressed: _cerrando ? null : _cerrarSesion,
        icon: _cerrando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Cerrar sesión'),
      ),
    );
  }
}
