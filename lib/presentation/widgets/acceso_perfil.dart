import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/router/rutas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'avatar_usuario.dart';

/// Avatar con el nombre, arriba a la derecha de la barra. Es la única
/// entrada a la cuenta (corrección del review: "Mi perfil" y el nombre eran
/// dos botones para lo mismo).
///
/// Al tocarlo abre un menú con "Mi perfil" y "Cerrar sesión" (HU-03), como
/// en la mayoría de las apps (H4 · Consistencia y estándares): así se puede
/// salir desde cualquier pantalla sin agregar otro botón a la barra, y cabe
/// también en el teléfono.
class AccesoPerfil extends StatelessWidget {
  const AccesoPerfil({
    super.key,
    required this.nombre,
    required this.rutaPerfil,
    this.fotoUrl,
  });

  final String nombre;
  final String? fotoUrl;
  final String rutaPerfil;

  /// Cierra la sesión y lleva al login, igual que `BotonCerrarSesion`.
  Future<void> _cerrarSesion(BuildContext context) async {
    // Se guardan antes de esperar: al cerrar sesión esta pantalla
    // desaparece y ya no se podrían pedir.
    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    final auth = ProviderScope.containerOf(context).read(authRepositoryProvider);

    try {
      await auth.cerrarSesion();
      router.go(Rutas.login);
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
    // maybeOf: en las pruebas la barra puede mostrarse fuera de un router.
    final enPerfil =
        GoRouter.maybeOf(context)?.state.uri.toString() == rutaPerfil;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        MenuItemButton(
          key: const Key('menu-mi-perfil'),
          leadingIcon: const Icon(Icons.person_outline_rounded, size: 20),
          onPressed: () => context.go(rutaPerfil),
          child: const Text('Mi perfil'),
        ),
        MenuItemButton(
          key: const Key('menu-cerrar-sesion'),
          leadingIcon: const Icon(Icons.logout_rounded, size: 20),
          onPressed: () => _cerrarSesion(context),
          child: const Text('Cerrar sesión'),
        ),
      ],
      builder: (context, menu, child) => Tooltip(
        message: 'Mi cuenta',
        child: Semantics(
          button: true,
          expanded: menu.isOpen,
          label: 'Mi cuenta, $primerNombre',
          excludeSemantics: true,
          child: Material(
            color: enPerfil || menu.isOpen
                ? AppColors.primarioClaro
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              key: const Key('acceso-perfil'),
              onTap: () => menu.isOpen ? menu.close() : menu.open(),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AvatarUsuario(nombre: nombre, fotoUrl: fotoUrl, tamano: 36),
                    if (!movil) ...[
                      const SizedBox(width: 10),
                      Text(
                        primerNombre,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      menu.isOpen
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.textoSecundario,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}