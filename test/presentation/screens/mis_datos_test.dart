import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/datos_personales.dart';
import 'package:limpiaya/domain/repositories/cuenta_repository.dart';
import 'package:limpiaya/presentation/screens/cuenta/mis_datos_screen.dart';

class _CuentaFalsa implements CuentaRepository {
  _CuentaFalsa({this.errorAlGuardar});

  final String? errorAlGuardar;
  final cambios = <(String, String)>[];

  @override
  Future<DatosPersonales> datosPersonales() async =>
      const DatosPersonales(nombre: 'Ana Pérez', telefono: '0414-1234567');

  @override
  Future<void> actualizarDatos({
    required String nombre,
    required String telefono,
  }) async {
    if (errorAlGuardar != null) throw AppException(errorAlGuardar!);
    cambios.add((nombre, telefono));
  }

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {}

  @override
  Future<void> desactivar() async {}
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
              onPressed: () => context.push(Rutas.misDatos),
              child: const Text('Mi perfil'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: Rutas.misDatos,
        builder: (context, state) => const MisDatosScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [cuentaRepositoryProvider.overrideWithValue(cuenta)],
    child: MaterialApp.router(
      theme: AppTheme.claro,
      routerConfig: router,
      builder: (context, child) => DefaultTextStyle(
        style: AppFonts.texto(const TextStyle()),
        child: child!,
      ),
    ),
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

void main() {
  testWidgets('HU-41: muestra el nombre y el teléfono actuales', (
    tester,
  ) async {
    await _abrir(tester, _CuentaFalsa());

    expect(find.text('Ana Pérez'), findsOneWidget);
    // Aparece en el campo y en el texto de ayuda del formato.
    expect(find.text('0414-1234567'), findsWidgets);
  });

  testWidgets('HU-41: guarda el nombre y el teléfono con formato', (
    tester,
  ) async {
    final cuenta = _CuentaFalsa();
    await _abrir(tester, cuenta);

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'Ana María Pérez');
    await tester.enterText(campos.at(1), '04241234567');
    await tester.tap(find.byKey(const Key('guardar-datos')));
    await tester.pumpAndSettle();

    expect(cuenta.cambios, [('Ana María Pérez', '0424-1234567')]);
    expect(find.text('Mi perfil'), findsOneWidget);
  });

  testWidgets('HU-41: un teléfono inválido no se guarda', (tester) async {
    final cuenta = _CuentaFalsa();
    await _abrir(tester, cuenta);

    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.byKey(const Key('guardar-datos')));
    await tester.pumpAndSettle();

    expect(find.text('Formato: 0414-1234567'), findsOneWidget);
    expect(cuenta.cambios, isEmpty);
  });

  testWidgets('HU-41: muestra el error si falla el guardado', (tester) async {
    await _abrir(tester, _CuentaFalsa(errorAlGuardar: 'Sin conexión'));

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana María');
    await tester.tap(find.byKey(const Key('guardar-datos')));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión'), findsOneWidget);
  });
}
