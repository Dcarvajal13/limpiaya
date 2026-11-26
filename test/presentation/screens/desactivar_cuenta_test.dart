import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/domain/entities/datos_personales.dart';
import 'package:limpiaya/domain/repositories/cuenta_repository.dart';
import 'package:limpiaya/presentation/screens/cuenta/desactivar_cuenta_screen.dart';

class _CuentaFalsa implements CuentaRepository {
  _CuentaFalsa({this.error});

  final String? error;
  int desactivadas = 0;

  @override
  Future<DatosPersonales> datosPersonales() async =>
      const DatosPersonales(nombre: 'Ana Pérez', telefono: '0414-1234567');

  @override
  Future<void> actualizarDatos({
    required String nombre,
    required String telefono,
  }) async {}

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {}

  @override
  Future<void> desactivar() async {
    if (error != null) throw AppException(error!);
    desactivadas++;
  }
}

class _AuthFalsa implements AuthRepository {
  int cerradas = 0;

  @override
  Future<void> cerrarSesion() async => cerradas++;

  @override
  Usuario? get usuarioActual => const Usuario(id: 'u1', email: 'a@b.com');

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registrarse({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario rol,
  }) async {}

  @override
  Future<Sesion?> obtenerSesion() async => null;

  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}
}

Widget _app(_CuentaFalsa cuenta, _AuthFalsa auth) {
  final router = GoRouter(
    initialLocation: Rutas.desactivarCuenta,
    routes: [
      GoRoute(
        path: Rutas.desactivarCuenta,
        builder: (context, state) => const DesactivarCuentaScreen(),
      ),
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      cuentaRepositoryProvider.overrideWithValue(cuenta),
      authRepositoryProvider.overrideWithValue(auth),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

Future<void> _pantalla(WidgetTester tester, _CuentaFalsa cuenta,
    _AuthFalsa auth) async {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(cuenta, auth));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-42 c2: con servicios asignados no desactiva y explica',
      (tester) async {
    final cuenta = _CuentaFalsa(
      error: 'Primero completa o cancela tus servicios asignados.',
    );
    final auth = _AuthFalsa();
    await _pantalla(tester, cuenta, auth);

    await tester.tap(find.byKey(const Key('desactivar-cuenta')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-desactivar')));
    await tester.pumpAndSettle();

    expect(
      find.text('Primero completa o cancela tus servicios asignados.'),
      findsOneWidget,
    );
    expect(cuenta.desactivadas, 0);
    expect(auth.cerradas, 0);
  });

  testWidgets('HU-42: si se arrepiente en el diálogo, no pasa nada',
      (tester) async {
    final cuenta = _CuentaFalsa();
    final auth = _AuthFalsa();
    await _pantalla(tester, cuenta, auth);

    await tester.tap(find.byKey(const Key('desactivar-cuenta')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancelar-desactivar')));
    await tester.pumpAndSettle();

    expect(cuenta.desactivadas, 0);
    expect(auth.cerradas, 0);
    expect(find.byKey(const Key('desactivar-cuenta')), findsOneWidget);
  });

  testWidgets('HU-42 c1: al confirmar desactiva y cierra la sesión',
      (tester) async {
    final cuenta = _CuentaFalsa();
    final auth = _AuthFalsa();
    await _pantalla(tester, cuenta, auth);

    await tester.tap(find.byKey(const Key('desactivar-cuenta')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-desactivar')));
    await tester.pumpAndSettle();

    expect(cuenta.desactivadas, 1);
    expect(auth.cerradas, 1);
    expect(find.text('Login'), findsOneWidget);
  });
}
