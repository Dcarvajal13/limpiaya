import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// TODO(HU-02A/HU-02B): formulario de inicio de sesión según el Figma.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaEnConstruccion(
      titulo: 'Iniciar sesión',
      historia: 'HU-02A / HU-02B',
      acciones: [
        TextButton(
          onPressed: () => context.go(Rutas.registro),
          child: const Text('¿No tienes cuenta? Regístrate'),
        ),
      ],
    );
  }
}
