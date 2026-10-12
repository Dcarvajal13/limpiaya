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
import 'package:limpiaya/presentation/widgets/boton_cerrar_sesion.dart';

/// Repositorio falso que cuenta cuántas veces se cerró sesión.
class _RepositorioFalso implements AuthRepository {
  _RepositorioFalso({this.falla = false});

  final bool falla;
  int cierres = 0;

  @override
  Future<void> cerrarSesion() async {
    if (falla) {
      throw const AppException('No pudimos cerrar tu sesión. Intenta de nuevo.');
    }
    cierres++;
  }

  @override
  Usuario? get usuarioActual => null;

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
}

/// App de prueba: arranca en "Mis solicitudes" con el botón arriba.
Widget _app(_RepositorioFalso repositorio) {
  final router = GoRouter(
    initialLocation: Rutas.inicioCliente,
    routes: [
      GoRoute(
        path: Rutas.landing,
        builder: (context, state) => const Scaffold(body: Text('Landing')),
      ),
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => Scaffold(
          appBar: AppBar(actions: const [BotonCerrarSesion()]),
          body: const Text('Mis solicitudes'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repositorio)],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-03: cerrar sesión lleva a la página de inicio', (tester) async {
    final repositorio = _RepositorioFalso();
    await tester.pumpWidget(_app(repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(repositorio.cierres, 1);
    expect(find.text('Landing'), findsOneWidget);
  });

  testWidgets('si falla, avisa y se queda en la pantalla', (tester) async {
    final repositorio = _RepositorioFalso(falla: true);
    await tester.pumpWidget(_app(repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cerrar tu sesión. Intenta de nuevo.'), findsOneWidget);
    expect(find.text('Mis solicitudes'), findsOneWidget);
  });
}
