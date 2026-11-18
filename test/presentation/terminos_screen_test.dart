import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/constants/app_constants.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/core/theme/movimiento.dart';
import 'package:limpiaya/presentation/screens/terminos/terminos_screen.dart';

/// Términos y condiciones: el correo de contacto aparece en el texto y en
/// el pie, y nada se sale de la pantalla.
void main() {
  setUpAll(() {
    AppFonts.usarGoogleFonts = false;
    Movimiento.ciclos = false;
  });

  for (final tamano in const [Size(360, 780), Size(1280, 900)]) {
    testWidgets('muestra el correo de contacto a ${tamano.width.toInt()} px', (tester) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.claro, home: const TerminosScreen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // En la sección de privacidad, en la de contacto y en el pie.
      expect(find.textContaining(AppConstants.correoSoporte), findsWidgets);
      expect(find.textContaining('Contacto'), findsWidgets);
    });
  }
}
