import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/presentation/screens/auth/login_screen.dart';

/// Repositorio falso: la única contraseña correcta es 'correcta123'.
class _RepositorioFalso implements AuthRepository {
  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}

  final correosUsados = <String>[];

  @override
  Usuario? get usuarioActual => null;

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    correosUsados.add(email);
    if (password != 'correcta123') {
      throw const AppException('Correo o contraseña incorrectos');
    }
  }

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

Future<_RepositorioFalso> _abrirLogin(
  WidgetTester tester, {
  Size tamano = const Size(1280, 900),
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repositorio = _RepositorioFalso();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repositorio)],
      child: MaterialApp(theme: AppTheme.claro, home: const LoginScreen()),
    ),
  );
  return repositorio;
}

Finder get _correo => find.byType(TextFormField).at(0);
Finder get _contrasena => find.byType(TextFormField).at(1);

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('con los campos vacíos pide llenarlos y no intenta entrar', (tester) async {
    final repositorio = await _abrirLogin(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
    expect(repositorio.correosUsados, isEmpty);
  });

  testWidgets('con datos incorrectos muestra "Correo o contraseña incorrectos"', (tester) async {
    final repositorio = await _abrirLogin(tester);

    await tester.enterText(_correo, '  Maria@Gmail.com ');
    await tester.enterText(_contrasena, 'equivocada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    // El correo se envía sin espacios y en minúsculas.
    expect(repositorio.correosUsados, ['maria@gmail.com']);
  });

  testWidgets('el error anterior se quita al intentar de nuevo', (tester) async {
    await _abrirLogin(tester);

    await tester.enterText(_correo, 'maria@gmail.com');
    await tester.enterText(_contrasena, 'equivocada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);

    await tester.enterText(_correo, 'correo-malo');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsNothing);
    expect(find.text('Correo inválido'), findsOneWidget);
  });

  testWidgets('con datos correctos entra sin mostrar errores', (tester) async {
    final repositorio = await _abrirLogin(tester);

    await tester.enterText(_correo, 'maria@gmail.com');
    await tester.enterText(_contrasena, 'correcta123');
    await tester.tap(find.text('Entrar'));
    // Sin pumpAndSettle: el botón queda girando hasta que el router
    // cambia de pantalla, y en esta prueba no hay router.
    await tester.pump();
    await tester.pump();

    expect(repositorio.correosUsados, ['maria@gmail.com']);
    expect(find.text('Correo o contraseña incorrectos'), findsNothing);
  });

  for (final tamano in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets('nada se sale de la pantalla a ${tamano.width.toInt()} px', (tester) async {
      await _abrirLogin(tester, tamano: tamano);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Hola de nuevo'), findsOneWidget);
    });
  }
}
