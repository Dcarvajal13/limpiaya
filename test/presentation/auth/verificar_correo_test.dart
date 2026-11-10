import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/router/verificacion_correo.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/domain/repositories/verificacion_correo_repository.dart';
import 'package:limpiaya/presentation/providers/verificacion_correo_provider.dart';
import 'package:limpiaya/presentation/screens/auth/correo_verificado_screen.dart';
import 'package:limpiaya/presentation/screens/auth/login_screen.dart';
import 'package:limpiaya/presentation/screens/auth/revisa_tu_correo_screen.dart';

/// 'nueva@correo.com' tiene la contraseña bien, pero no ha verificado su
/// correo.
class _AuthFalso implements AuthRepository {
  _AuthFalso({this.conSesion = false});

  final bool conSesion;

  @override
  Usuario? get usuarioActual =>
      conSesion ? const Usuario(id: 'u1', email: 'nueva@correo.com') : null;

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    if (email == 'nueva@correo.com' && password == 'correcta123') {
      throw CorreoSinVerificarException(email);
    }
    throw const AppException('Correo o contraseña incorrectos');
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

  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}
}

class _ReenvioFalso implements VerificacionCorreoRepository {
  _ReenvioFalso({this.limite = false});

  /// Simula el límite de correos de Supabase.
  final bool limite;
  final enviados = <String>[];

  @override
  Future<void> reenviar(String email) async {
    if (limite) {
      throw const AppException(
        'Ya te enviamos un correo hace poco. Espera un minuto e intenta de '
        'nuevo.',
      );
    }
    enviados.add(email);
  }
}

class _EnlaceFijo extends EnlaceCorreo {
  _EnlaceFijo(this.inicial);

  final EstadoEnlaceCorreo inicial;

  @override
  EstadoEnlaceCorreo build() => inicial;
}

void _pantalla(WidgetTester tester, {Size tamano = const Size(1280, 900)}) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _login(_ReenvioFalso reenvio) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_AuthFalso()),
        verificacionCorreoRepositoryProvider.overrideWithValue(reenvio),
      ],
      child: MaterialApp(theme: AppTheme.claro, home: const LoginScreen()),
    );

Future<void> _entrarSinVerificar(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'nueva@correo.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'correcta123');
  // En el teléfono el botón queda más abajo: primero se baja hasta él.
  await tester.ensureVisible(find.text('Entrar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

Widget _correoVerificado(EstadoEnlaceCorreo estado, {bool conSesion = false}) {
  final router = GoRouter(
    initialLocation: Rutas.correoVerificado,
    routes: [
      GoRoute(
        path: Rutas.correoVerificado,
        builder: (context, state) => const CorreoVerificadoScreen(),
      ),
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthFalso(conSesion: conSesion)),
      enlaceCorreoProvider.overrideWith(() => _EnlaceFijo(estado)),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  group('HU-40 c2 · iniciar sesión sin haber verificado el correo', () {
    testWidgets('muestra el aviso con "Reenviar correo"', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_login(_ReenvioFalso()));
      await _entrarSinVerificar(tester);

      expect(find.text('Aún no verificas tu correo'), findsOneWidget);
      expect(find.text('Reenviar correo'), findsOneWidget);
      // El aviso dice a qué correo se mandó el enlace.
      expect(
        find.descendant(
          of: find.byKey(const Key('aviso-verificar-correo')),
          matching: find.textContaining('nueva@correo.com'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('"Reenviar correo" vuelve a enviar el enlace', (tester) async {
      _pantalla(tester);
      final reenvio = _ReenvioFalso();
      await tester.pumpWidget(_login(reenvio));
      await _entrarSinVerificar(tester);

      await tester.tap(find.byKey(const Key('reenviar-correo')));
      await tester.pumpAndSettle();

      expect(reenvio.enviados, ['nueva@correo.com']);
      expect(find.text('Te enviamos otro correo.'), findsOneWidget);
      expect(find.text('Reenviar otra vez'), findsOneWidget);
    });

    testWidgets('si se pide muy seguido, explica que espere', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_login(_ReenvioFalso(limite: true)));
      await _entrarSinVerificar(tester);

      await tester.tap(find.byKey(const Key('reenviar-correo')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error-reenviar')), findsOneWidget);
      expect(find.text('Te enviamos otro correo.'), findsNothing);
    });

    testWidgets('con datos incorrectos no sale el aviso de verificación',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_login(_ReenvioFalso()));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'nueva@correo.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'equivocada');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      expect(find.text('Aún no verificas tu correo'), findsNothing);
    });

    testWidgets('el aviso cabe en el teléfono (390x844)', (tester) async {
      _pantalla(tester, tamano: const Size(390, 844));
      await tester.pumpWidget(_login(_ReenvioFalso()));
      await _entrarSinVerificar(tester);

      expect(find.text('Aún no verificas tu correo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HU-40 · después de registrarse', () {
    testWidgets('"Revisa tu correo" muestra el correo y deja reenviarlo',
        (tester) async {
      _pantalla(tester);
      final reenvio = _ReenvioFalso();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            verificacionCorreoRepositoryProvider.overrideWithValue(reenvio),
          ],
          child: MaterialApp(
            theme: AppTheme.claro,
            home: const RevisaTuCorreoScreen(email: 'nueva@correo.com'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.textContaining('nueva@correo.com'), findsOneWidget);
      expect(find.text('Ya lo confirmé, iniciar sesión'), findsOneWidget);

      await tester.tap(find.byKey(const Key('reenviar-correo')));
      await tester.pumpAndSettle();
      expect(reenvio.enviados, ['nueva@correo.com']);
    });
  });

  group('HU-40 · al abrir el enlace del correo', () {
    testWidgets('c1: "¡Tu correo quedó verificado!" y sigue a su inicio',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(
        _correoVerificado(EstadoEnlaceCorreo.verificado, conSesion: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Tu correo quedó verificado!'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('c3: si el enlace ya se usó, "Tu correo ya está verificado"',
        (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_correoVerificado(EstadoEnlaceCorreo.yaUsado));
      await tester.pumpAndSettle();

      expect(find.text('Tu correo ya está verificado'), findsOneWidget);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('un enlace dañado explica qué hacer', (tester) async {
      _pantalla(tester);
      await tester.pumpWidget(_correoVerificado(EstadoEnlaceCorreo.error));
      await tester.pumpAndSettle();

      expect(find.text('No pudimos verificar tu correo'), findsOneWidget);
    });

    testWidgets('cabe en el teléfono (390x844)', (tester) async {
      _pantalla(tester, tamano: const Size(390, 844));
      await tester.pumpWidget(_correoVerificado(EstadoEnlaceCorreo.yaUsado));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
