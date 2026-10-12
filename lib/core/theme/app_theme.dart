import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Tema global de LimpiaYa, tomado del prototipo de Figma.
///
/// Todo lo que se define aquí (botones, campos, tarjetas, chips...) se aplica
/// solo en todas las pantallas. Una pantalla nueva no necesita estilos propios:
/// usa FilledButton, OutlinedButton, TextFormField, Card, ChoiceChip, etc.
///
/// Guía rápida de botones:
/// - Acción principal  → FilledButton            (verde)
/// - Acción secundaria → OutlinedButton          (borde verde)
/// - Enlace o acción leve → TextButton
/// - Destacado (ámbar) → FilledButton(style: AppTheme.botonAmbar)
/// - Peligro           → FilledButton(style: AppTheme.botonPeligro)
abstract final class AppTheme {
  static const radioBoton = 12.0;
  static const radioTarjeta = 16.0;
  static const altoBoton = 48.0;

  static final TextTheme textos = _textos();

  static ThemeData get claro {
    const colores = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primario,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarioClaro,
      onPrimaryContainer: AppColors.primarioOscuro,
      secondary: AppColors.ambar,
      onSecondary: AppColors.primarioOscuro,
      secondaryContainer: AppColors.arena,
      onSecondaryContainer: AppColors.texto,
      tertiary: AppColors.acento,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.superficie,
      onSurface: AppColors.texto,
      onSurfaceVariant: AppColors.textoSecundario,
      outline: AppColors.borde,
      outlineVariant: AppColors.borde,
    );

    final formaBoton = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radioBoton),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: textos,
      dividerTheme: const DividerThemeData(color: AppColors.borde, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.superficie,
        foregroundColor: AppColors.texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textos.titleLarge,
        shape: const Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.deshabilitado,
          disabledForegroundColor: AppColors.textoDeshabilitado,
          minimumSize: const Size(64, altoBoton),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: formaBoton,
          textStyle: textos.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primario,
          minimumSize: const Size(64, altoBoton),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: const BorderSide(color: AppColors.primario),
          shape: formaBoton,
          textStyle: textos.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primario,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: formaBoton,
          textStyle: textos.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
        labelStyle: textos.titleSmall,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorStyle: textos.bodySmall?.copyWith(color: AppColors.error),
        border: _bordeCampo(AppColors.borde),
        enabledBorder: _bordeCampo(AppColors.borde),
        focusedBorder: _bordeCampo(AppColors.primario, ancho: 2),
        errorBorder: _bordeCampo(AppColors.error),
        focusedErrorBorder: _bordeCampo(AppColors.error, ancho: 2),
        disabledBorder: _bordeCampo(AppColors.deshabilitado),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radioTarjeta),
          side: const BorderSide(color: AppColors.borde),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.superficie,
        selectedColor: AppColors.primarioClaro,
        disabledColor: AppColors.deshabilitado,
        labelStyle: textos.labelMedium,
        secondaryLabelStyle: textos.labelMedium?.copyWith(color: AppColors.primario),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: const StadiumBorder(),
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith(
          (estados) => BorderSide(
            color: estados.contains(WidgetState.selected)
                ? AppColors.primario
                : AppColors.borde,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? AppColors.primario
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.textoSecundario, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textos.headlineSmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primarioOscuro,
        contentTextStyle: textos.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioBoton)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primario,
        unselectedLabelColor: AppColors.textoSecundario,
        indicatorColor: AppColors.primario,
        labelStyle: textos.labelLarge,
        unselectedLabelStyle: textos.labelLarge,
        dividerColor: AppColors.borde,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primario,
      ),
    );
  }

  /// Botón ámbar (por ejemplo "Publicar solicitud" sobre fondo oscuro).
  static final ButtonStyle botonAmbar = FilledButton.styleFrom(
    backgroundColor: AppColors.ambar,
    foregroundColor: AppColors.primarioOscuro,
  );

  /// Botón de peligro (cancelar un servicio, rechazar).
  static final ButtonStyle botonPeligro = FilledButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
  );

  static OutlineInputBorder _bordeCampo(Color color, {double ancho = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radioBoton),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }

  static TextTheme _textos() {
    TextStyle titulo(double tamano, FontWeight peso) => AppFonts.titulos(
          TextStyle(
            fontSize: tamano,
            fontWeight: peso,
            height: 1.1,
            letterSpacing: -0.025 * tamano,
            color: AppColors.texto,
          ),
        );

    TextStyle cuerpo(double tamano, FontWeight peso, {Color? color}) =>
        AppFonts.texto(
          TextStyle(
            fontSize: tamano,
            fontWeight: peso,
            height: 1.5,
            color: color ?? AppColors.texto,
          ),
        );

    return TextTheme(
      displayLarge: titulo(64, FontWeight.w800),
      displayMedium: titulo(48, FontWeight.w800),
      displaySmall: titulo(40, FontWeight.w800),
      headlineLarge: titulo(36, FontWeight.w700),
      headlineMedium: titulo(28, FontWeight.w700),
      headlineSmall: titulo(24, FontWeight.w700),
      titleLarge: titulo(20, FontWeight.w700),
      titleMedium: cuerpo(16, FontWeight.w700),
      titleSmall: cuerpo(14, FontWeight.w700),
      bodyLarge: cuerpo(18, FontWeight.w400, color: AppColors.textoSecundario),
      bodyMedium: cuerpo(16, FontWeight.w400),
      bodySmall: cuerpo(14, FontWeight.w400, color: AppColors.textoSecundario),
      labelLarge: cuerpo(16, FontWeight.w700),
      labelMedium: cuerpo(14, FontWeight.w600),
      labelSmall: cuerpo(12, FontWeight.w700),
    );
  }
}
