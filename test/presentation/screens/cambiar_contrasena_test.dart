import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/repositories/cuenta_repository.dart';
import 'package:limpiaya/presentation/screens/cuenta/cambiar_contrasena_screen.dart';

class _CuentaFalsa implements CuentaRepository {
  _CuentaFalsa({this.error});

  final String? error;
  final cambios = <(String, String)>[];
  int desactivadas = 0;

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    cambios.add((actual, nueva));
    if (error != null) throw AppException(error!);
  }

  @override
  Future<void> desactivar() async => desactivadas++;
}

Widget _app(_CuentaFalsa cuenta) {
  final router = GoRouter(
    initialLocation: '/perfil',
    routes: [
      GoRoute(
        path: '/perfil',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push(Rutas.cambiarContrasena),
              child: const Text('Mi perfil'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Rutas.cambiarContrasena,
        builder: (context, state) => const CambiarContrasenaScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [cuentaRepositoryProvider.overrideWithValue(cuenta)],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

Future<void> _abrir(WidgetTester tester, _CuentaFalsa cuenta) async {
  tester.view.physicalSize = const Size(1280, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(cuenta));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mi perfil'));
  await tester.pumpAndSettle();
}

Future<void> _llenar(
  WidgetTester tester, {
  required String actual,
  required String nueva,
  required String repetir,
}) async {
  await tester.enterText(find.byType(TextFormField).at(0), actual);
  await tester.enterText(find.byType(TextFormField).at(1), nueva);
  await tester.enterText(find.byType(TextFormField).at(2), repetir);
  await tester.tap(find.byKey(const Key('guardar-contrasena')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-39 c3: si la nueva y la confirmación no coinciden, no guarda',
      (tester) async {
    final cuenta = _CuentaFalsa();
    await _abrir(tester, cuenta);

    await _llenar(
      tester,
      actual: 'actual123',
      nueva: 'nueva12345',
      repetir: 'otra12345',
    );

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(cuenta.cambios, isEmpty);
  });

  testWidgets('HU-39 c2: con la contraseña actual incorrecta ve el error',
      (tester) async {
    final cuenta = _CuentaFalsa(error: 'La contraseña actual no es correcta');
    await _abrir(tester, cuenta);

    await _llenar(
      tester,
      actual: 'equivocada',
      nueva: 'nueva12345',
      repetir: 'nueva12345',
    );

    expect(find.text('La contraseña actual no es correcta'), findsOneWidget);
    expect(cuenta.cambios, [('equivocada', 'nueva12345')]);
    expect(find.byKey(const Key('guardar-contrasena')), findsOneWidget);
  });

  testWidgets('HU-39 c1: con los datos correctos guarda y confirma',
      (tester) async {
    final cuenta = _CuentaFalsa();
    await _abrir(tester, cuenta);

    await _llenar(
      tester,
      actual: 'actual123',
      nueva: 'nueva12345',
      repetir: 'nueva12345',
    );

    expect(cuenta.cambios, [('actual123', 'nueva12345')]);
    expect(find.text('Contraseña actualizada'), findsOneWidget);
    // Vuelve al perfil desde donde se abrió.
    expect(find.text('Mi perfil'), findsOneWidget);
  });
}
