import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/presentation/screens/landing/landing_screen.dart';

/// Pruebas de la landing (HU-62).
///
/// Se usa un router de prueba con pantallas falsas de registro y login,
/// así no hace falta Supabase para correrlas.
Widget _appDePrueba() {
  final router = GoRouter(
    initialLocation: Rutas.landing,
    routes: [
      GoRoute(
        path: Rutas.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: Rutas.registro,
        builder: (context, state) => Scaffold(
          body: Text('Pantalla de registro ${state.uri.queryParameters['rol'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const Scaffold(body: Text('Pantalla de login')),
      ),
    ],
  );
  return MaterialApp.router(theme: AppTheme.claro, routerConfig: router);
}

/// Cambia el tamaño de la "pantalla" de la prueba.
void _usarPantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  // Sin internet en las pruebas: no descargar fuentes de Google.
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('criterio 1: muestra qué es LimpiaYa y los cinco pasos', (tester) async {
    _usarPantalla(tester, const Size(1280, 900));
    await tester.pumpWidget(_appDePrueba());
    await tester.pumpAndSettle();

    expect(find.text('Elige con calma a quien entra a tu casa.'), findsOneWidget);
    for (final paso in ['Publica', 'Se postulan', 'Elige', 'Servicio', 'Califican']) {
      expect(find.text(paso), findsOneWidget, reason: 'Falta el paso "$paso"');
    }
  });

  testWidgets('criterio 2: "Registrarme" lleva al registro', (tester) async {
    _usarPantalla(tester, const Size(1280, 900));
    await tester.pumpWidget(_appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Registrarme'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pantalla de registro'), findsOneWidget);
  });

  testWidgets('criterio 3: "Iniciar sesión" lleva al inicio de sesión', (tester) async {
    _usarPantalla(tester, const Size(1280, 900));
    await tester.pumpWidget(_appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla de login'), findsOneWidget);
  });

  testWidgets('el selector cambia el mensaje para trabajadoras', (tester) async {
    _usarPantalla(tester, const Size(1280, 900));
    await tester.pumpWidget(_appDePrueba());
    await tester.pumpAndSettle();

    // El primero es el del selector de arriba; hay otro al final de la página.
    await tester.tap(find.text('Quiero trabajar').first);
    await tester.pumpAndSettle();

    expect(find.text('Tu trabajo habla por ti.'), findsOneWidget);
  });

  // Criterio 5: si algo no cabe a lo ancho, Flutter marca un error de
  // "overflow" y la prueba falla.
  for (final tamano in const [Size(360, 780), Size(800, 1000), Size(1440, 900)]) {
    testWidgets('criterio 5: nada se sale de la pantalla a ${tamano.width.toInt()} px', (
      tester,
    ) async {
      _usarPantalla(tester, tamano);
      await tester.pumpWidget(_appDePrueba());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Registrarme'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });
  }
}
