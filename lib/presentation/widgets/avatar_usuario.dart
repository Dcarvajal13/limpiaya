import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/texto.dart';

/// Avatar circular: foto si hay, si no, las iniciales del nombre.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.tamano = 48,
  });

  final String nombre;
  final String? fotoUrl;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    // Accesibilidad (WCAG 1.1.1): el avatar siempre va al lado del nombre de
    // la persona (o dentro de un botón con su propio nombre, como "Mi
    // perfil"), así que es decorativo. Antes NVDA leía las iniciales sueltas
    // ("C P") antes del nombre; ahora el lector lo salta.
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: tamano / 2,
        backgroundColor: AppColors.primarioClaro,
        foregroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
        child: Text(
          Texto.iniciales(nombre),
          style: TextStyle(
            fontSize: tamano * 0.3,
            fontWeight: FontWeight.w800,
            color: AppColors.primario,
          ),
        ),
      ),
    );
  }
}
