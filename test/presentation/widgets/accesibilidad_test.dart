import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/theme/app_colors.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/presentation/widgets/enlace_subrayado.dart';

/// Pruebas de la actividad de accesibilidad web (WCAG 2.2 AA).
void main() {
  setUpAll(() {
    AppFonts.usarGoogleFonts = false;
  });

  Widget app(Widget child) => MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(body: Center(child: child)),
      );

  group('Navegación con teclado (WCAG 2.1.1)', () {
    testWidgets('el enlace de texto se alcanza con Tab y se abre con Enter',
        (tester) async {
      var toques = 0;
      await tester.pumpWidget(app(
        EnlaceSubrayado(
          texto: 'Términos y condiciones',
          onTap: () => toques++,
        ),
      ));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('el enlace también se abre con Espacio', (tester) async {
      var toques = 0;
      await tester.pumpWidget(app(
        EnlaceSubrayado(texto: 'Política de privacidad', onTap: () => toques++),
      ));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(toques, 1);
    });

    testWidgets('el enlace sigue funcionando con el ratón', (tester) async {
      var toques = 0;
      await tester.pumpWidget(app(
        EnlaceSubrayado(texto: 'Sistema de diseño', onTap: () => toques++),
      ));

      await tester.tap(find.text('Sistema de diseño'));
      await tester.pumpAndSettle();

      expect(toques, 1);
    });
  });

  group('Contraste (WCAG 1.4.3 y 1.4.11)', () {
    double contraste(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
      return (claro + 0.05) / (oscuro + 0.05);
    }

    test('texto principal y secundario pasan 4.5:1 sobre el fondo', () {
      expect(contraste(AppColors.texto, AppColors.fondo), greaterThanOrEqualTo(4.5));
      expect(contraste(AppColors.textoSecundario, AppColors.fondo),
          greaterThanOrEqualTo(4.5));
      expect(contraste(AppColors.textoSecundario, AppColors.superficie),
          greaterThanOrEqualTo(4.5));
      expect(contraste(Colors.white, AppColors.primario), greaterThanOrEqualTo(4.5));
    });

    test('el color terciario del tema pasa 4.5:1 sobre el fondo', () {
      final tertiary = AppTheme.claro.colorScheme.tertiary;
      expect(contraste(tertiary, AppColors.fondo), greaterThanOrEqualTo(4.5));
    });

    test('bordes de botones y anillo de foco pasan 3:1', () {
      expect(contraste(AppColors.bordeBoton, AppColors.superficie),
          greaterThanOrEqualTo(3));
      expect(contraste(AppColors.bordeBoton, AppColors.fondo),
          greaterThanOrEqualTo(3));
      expect(contraste(AppColors.bordeBoton, AppColors.arena),
          greaterThanOrEqualTo(3));
      expect(contraste(AppColors.foco, AppColors.fondo), greaterThanOrEqualTo(3));
      expect(contraste(AppColors.verdeSobreOscuro, AppColors.primarioOscuro),
          greaterThanOrEqualTo(3));
    });
  });
}
