import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global. Lo que se defina aquí (botones, campos de texto, fuentes)
/// se aplica a todas las pantallas sin repetir estilos.
///
/// TODO(equipo): ajustar tipografía y estilos con el Figma.
abstract final class AppTheme {
  static ThemeData get claro {
    final colores = ColorScheme.fromSeed(
      seedColor: AppColors.primario,
      primary: AppColors.primario,
      secondary: AppColors.secundario,
      error: AppColors.error,
    );

    return ThemeData(
      colorScheme: colores,
      scaffoldBackgroundColor: AppColors.fondo,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
