import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'avatar_usuario.dart';

/// Avatar con el nombre, arriba a la derecha de la barra. Es la única
/// entrada al perfil (corrección del review: "Mi perfil" y el nombre eran
/// dos botones para lo mismo). "Cerrar sesión" está dentro del perfil.
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

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
    // maybeOf: en las pruebas la barra puede mostrarse fuera de un router.
    final enPerfil =
        GoRouter.maybeOf(context)?.state.uri.toString() == rutaPerfil;

    return Tooltip(
      message: 'Mi perfil',
      child: Material(
        color: enPerfil ? AppColors.primarioClaro : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('acceso-perfil'),
          onTap: () => context.go(rutaPerfil),
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
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.textoSecundario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
