import 'package:flutter/material.dart';

/// Colores de LimpiaYa.
///
/// TODO(equipo): reemplazar por los colores exactos del archivo de Figma.
/// Las pantallas NUNCA escriben colores a mano (Color(0xFF...)):
/// siempre usan AppColors o Theme.of(context).colorScheme.
abstract final class AppColors {
  static const primario = Color(0xFF00897B);
  static const secundario = Color(0xFFFFB300);
  static const error = Color(0xFFD32F2F);
  static const fondo = Color(0xFFF7F9F9);
  static const texto = Color(0xFF1F2933);
}
