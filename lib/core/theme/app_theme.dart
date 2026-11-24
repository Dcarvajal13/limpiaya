import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Tema global de LimpiaYa (dirección "Testimonio en movimiento").
///
/// Todo lo que se define aquí (botones, campos, tarjetas, chips...) se aplica
/// solo en todas las pantallas. Una pantalla nueva no necesita estilos propios:
/// usa FilledButton, OutlinedButton, TextFormField, Card, ChoiceChip, etc.
///
/// Guía rápida de botones:
/// - Acción principal  → FilledButton            (azul pizarra)
/// - Acción secundaria → OutlinedButton          (borde gris azulado)
/// - Enlace o acción leve → TextButton
/// - Sobre fondo oscuro → FilledButton(style: AppTheme.botonAmbar) (blanco)
/// - Peligro           → FilledButton(style: AppTheme.botonPeligro)
abstract final class AppTheme {
  static const radioBoton = 12.0;
  static const radioTarjeta = 20.0;
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
      // acento da 4.4:1 sobre el fondo (no llega a 4.5:1); acentoTexto sí.
      tertiary: AppColors.acentoTexto,
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
      // Resaltado de foco de InkWell (pestañas, logo, tarjetas): más fuerte
      // que el 10 % que trae Material para que se note con el teclado.
      focusColor: AppColors.primario.withValues(alpha: 0.2),
      textTheme: textos,
      dividerTheme: const DividerThemeData(color: AppColors.borde, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fondo,
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
        ).copyWith(side: anilloFoco(AppColors.foco)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primario,
          minimumSize: const Size(64, altoBoton),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: formaBoton,
          textStyle: textos.labelLarge,
        ).copyWith(
          side: anilloFoco(
            AppColors.foco,
            normal: const BorderSide(color: AppColors.bordeBoton, width: 1.5),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primario,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: formaBoton,
          textStyle: textos.labelLarge,
        ).copyWith(side: anilloFoco(AppColors.foco)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(side: anilloFoco(AppColors.foco)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
        labelStyle: textos.titleSmall,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorStyle: textos.bodySmall?.copyWith(color: AppColors.error),
        border: _bordeCampo(AppColors.bordeCampo),
        enabledBorder: _bordeCampo(AppColors.bordeCampo),
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
        selectedColor: AppColors.primario,
        disabledColor: AppColors.deshabilitado,
        labelStyle: textos.labelMedium,
        secondaryLabelStyle: textos.labelMedium?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radioBoton)),
        showCheckmark: false,
        side: WidgetStateBorderSide.resolveWith(
          (estados) => estados.contains(WidgetState.focused)
              ? const BorderSide(color: AppColors.foco, width: 3)
              : BorderSide(
                  color: estados.contains(WidgetState.selected)
                      ? AppColors.primario
                      : AppColors.bordeBoton,
                  width: 1.5,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  /// Anillo de foco para el teclado (WCAG 2.4.7 "Foco visible"): cuando un
  /// botón recibe el foco con Tab se le dibuja un borde de 3 px por fuera,
  /// del color [color]. Si el botón ya tiene un borde, va en [normal].
  static WidgetStateProperty<BorderSide?> anilloFoco(
    Color color, {
    BorderSide? normal,
  }) {
    return WidgetStateProperty.resolveWith((estados) {
      if (estados.contains(WidgetState.focused)) {
        return BorderSide(
          color: color,
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        );
      }
      return normal;
    });
  }

  /// Botón claro para fondos oscuros (por ejemplo "Necesito limpieza" en
  /// la franja final). Conserva el nombre de la paleta anterior.
  static final ButtonStyle botonAmbar = FilledButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.primarioOscuro,
  ).copyWith(side: anilloFoco(AppColors.verdeSobreOscuro));

  /// Botón de contorno blanco para fondos oscuros ("Quiero trabajar").
  static final ButtonStyle botonContornoSobreOscuro = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
  ).copyWith(
    side: anilloFoco(
      AppColors.verdeSobreOscuro,
      normal: const BorderSide(color: Colors.white, width: 1.5),
    ),
  );

  /// Botón de peligro (cancelar un servicio, rechazar).
  static final ButtonStyle botonPeligro = FilledButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
  ).copyWith(side: anilloFoco(AppColors.foco));

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
            letterSpacing: -0.015 * tamano,
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
      // Newsreader se ve mejor en peso medio: el tamaño da la jerarquía.
      displayLarge: titulo(64, FontWeight.w500),
      displayMedium: titulo(48, FontWeight.w500),
      displaySmall: titulo(40, FontWeight.w500),
      headlineLarge: titulo(38, FontWeight.w500),
      headlineMedium: titulo(30, FontWeight.w500),
      headlineSmall: titulo(26, FontWeight.w500),
      titleLarge: titulo(22, FontWeight.w500),
      titleMedium: cuerpo(16, FontWeight.w700),
      titleSmall: cuerpo(14, FontWeight.w700),
      bodyLarge: cuerpo(18, FontWeight.w400, color: AppColors.textoSecundario),
      bodyMedium: cuerpo(16, FontWeight.w400),
      bodySmall: cuerpo(14, FontWeight.w400, color: AppColors.textoSecundario),
      labelLarge: cuerpo(16, FontWeight.w600),
      labelMedium: cuerpo(14, FontWeight.w600),
      labelSmall: cuerpo(12, FontWeight.w700),
    );
  }
}
