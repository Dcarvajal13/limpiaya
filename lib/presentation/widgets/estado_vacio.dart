import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Lo que se muestra cuando una lista está vacía.
///
/// Ejemplo (HU-08 c3):
/// EstadoVacio(
///   icono: Icons.inbox_outlined,
///   titulo: 'Aún no tienes solicitudes',
///   textoBoton: 'Publicar mi primera solicitud',
///   onPressed: () => context.go(Rutas.publicar),
/// )
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.textoBoton,
    this.onPressed,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? textoBoton;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primarioClaro,
              child: Icon(icono, size: 30, color: AppColors.primario),
            ),
            const SizedBox(height: 16),
            Text(titulo, style: textos.titleLarge, textAlign: TextAlign.center),
            if (mensaje != null) ...[
              const SizedBox(height: 6),
              Text(mensaje!, style: textos.bodySmall, textAlign: TextAlign.center),
            ],
            if (textoBoton != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onPressed, child: Text(textoBoton!)),
            ],
          ],
        ),
      ),
    );
  }
}
