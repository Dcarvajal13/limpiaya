import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/presentation/providers/recuperacion_provider.dart';
import 'package:limpiaya/presentation/screens/auth/login_screen.dart';
import 'package:limpiaya/presentation/screens/auth/nueva_contrasena_screen.dart';
import 'package:limpiaya/presentation/screens/auth/recuperar_contrasena_screen.dart';

class _AuthFalso implements AuthRepository {
  final correos = <String>[];
  final contrasenas = <String>[];

  @override
  Future<void> enviarRecuperacion(String email) async => correos.add(email);

  @override
  Future<void> cambiarPassword(String nueva) async => contrasenas.add(nueva);

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

  @override
  Future<void> cerrarSesion() async {}
}

Widget _app(_AuthFalso auth, String inicial) {
  final router = GoRouter(
    initialLocation: inicial,
    routes: [
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Rutas.recuperarContrasena,
        builder: (context, state) => const RecuperarContrasenaScreen(),
      ),
      GoRoute(
        path: Rutas.nuevaContrasena,
        builder: (context, state) => const NuevaContrasenaScreen(),
      ),
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(auth)],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('el login tiene "¿Olvidaste tu contraseña?" y lleva a la pantalla',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_AuthFalso(), Rutas.login));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Enviarme el enlace'), findsOneWidget);
  });

  testWidgets('envía el enlace y muestra "Revisa tu correo"', (tester) async {
    _pantallaGrande(tester);
    final auth = _AuthFalso();
    await tester.pumpWidget(_app(auth, Rutas.recuperarContrasena));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), ' Maria@Correo.com ');
    await tester.tap(find.text('Enviarme el enlace'));
    await tester.pumpAndSettle();

    expect(auth.correos, ['maria@correo.com']);
    expect(find.text('Revisa tu correo'), findsOneWidget);
  });

  testWidgets('con un correo inválido no envía nada', (tester) async {
    _pantallaGrande(tester);
    final auth = _AuthFalso();
    await tester.pumpWidget(_app(auth, Rutas.recuperarContrasena));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'maria');
    await tester.tap(find.text('Enviarme el enlace'));
    await tester.pumpAndSettle();

    expect(auth.correos, isEmpty);
  });

  testWidgets('nueva contraseña: si no coinciden no la guarda', (tester) async {
    _pantallaGrande(tester);
    final auth = _AuthFalso();
    await tester.pumpWidget(_app(auth, Rutas.nuevaContrasena));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'nueva12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'otra12345');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(auth.contrasenas, isEmpty);
  });

  testWidgets('nueva contraseña: la guarda, termina la recuperación y entra',
      (tester) async {
    _pantallaGrande(tester);
    final auth = _AuthFalso();
    await tester.pumpWidget(_app(auth, Rutas.nuevaContrasena));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'nueva12345');
    await tester.enterText(find.byType(TextFormField).at(1), 'nueva12345');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();

    expect(auth.contrasenas, ['nueva12345']);
    expect(find.text('Inicio'), findsOneWidget);

    final contenedor = ProviderScope.containerOf(
      tester.element(find.text('Inicio')),
    );
    expect(contenedor.read(recuperandoContrasenaProvider), isFalse);
  });
}
