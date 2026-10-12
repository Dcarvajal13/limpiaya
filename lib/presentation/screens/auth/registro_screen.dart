import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// TODO(HU-01): formulario de registro según el Figma.
/// Las validaciones ya están en core/utils/validadores.dart.
class RegistroScreen extends StatelessWidget {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaEnConstruccion(
      titulo: 'Crear cuenta',
      historia: 'HU-01',
      acciones: [
        TextButton(
          onPressed: () => context.go(Rutas.login),
          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
        ),
      ],
    );
  }
}
