import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/presentation/screens/auth/registro_screen.dart';

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('registro: enviar vacío marca todos los campos', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegistroScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio'), findsWidgets);
    expect(find.text('Elige una opción'), findsOneWidget);
    expect(find.text('Elige el prefijo'), findsOneWidget);
  });

  testWidgets('registro: el teléfono solo acepta prefijos y 7 números',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegistroScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // El prefijo se escoge, no se escribe.
    await tester.tap(find.byKey(const Key('registro-codigo')));
    await tester.pumpAndSettle();
    for (final prefijo in const ['0412', '0414', '0416', '0422', '0424', '0426']) {
      expect(find.text(prefijo), findsWidgets);
    }
    await tester.tap(find.text('0414').last);
    await tester.pumpAndSettle();

    // El campo de números filtra letras y corta en 7 dígitos.
    await tester.enterText(
        find.byKey(const Key('registro-numero')), 'abc1234');
    await tester.pumpAndSettle();
    final campo = tester.widget<TextFormField>(
      find.byKey(const Key('registro-numero')),
    );
    expect(campo.controller?.text, '1234');

    await tester.enterText(
        find.byKey(const Key('registro-numero')), '123456789');
    await tester.pumpAndSettle();
    expect(campo.controller?.text, '1234567');
  });
}
