import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/perfil_cliente.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/domain/repositories/cliente_repository.dart';
import 'package:limpiaya/presentation/screens/cliente/perfil_cliente_screen.dart';

/// Repositorio falso: guarda en memoria lo que le mandan.
class _ClienteFalso implements ClienteRepository {
  PerfilCliente perfil = const PerfilCliente();
  int? ultimoZonaId;
  String? ultimaDireccion;

  @override
  Future<List<Zona>> zonasDisponibles() async => const [
        Zona(
          id: 1,
          nombre: 'Sabana Grande',
          municipio: 'Libertador',
          parroquia: 'El Recreo',
        ),
        Zona(
          id: 2,
          nombre: 'Altamira',
          municipio: 'Chacao',
          parroquia: 'Chacao',
        ),
      ];

  @override
  Future<PerfilCliente> miPerfil() async => perfil;

  @override
  Future<void> guardarPerfil({
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    ultimoZonaId = zonaId;
    ultimaDireccion = direccion;
    perfil = PerfilCliente(
      zona: Zona(id: zonaId, nombre: 'Sabana Grande'),
      direccion: direccion,
      puntoReferencia: puntoReferencia,
    );
  }
}

/// Auth falso: hay sesión de cliente sin el perfil completo.
class _AuthFalso implements AuthRepository {
  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}

  @override
  Usuario? get usuarioActual => const Usuario(id: 'u1', email: 'ana@correo.com');

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> cerrarSesion() async {}

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
  Future<Sesion?> obtenerSesion() async => const Sesion(
        id: 'u1',
        rol: RolUsuario.cliente,
        nombre: 'Ana',
        perfilCompleto: false,
      );
}

Widget _app(_ClienteFalso repo) {
  final router = GoRouter(
    initialLocation: Rutas.perfilCliente,
    routes: [
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) =>
            const Scaffold(body: Text('Inicio cliente')),
      ),
      GoRoute(
        path: Rutas.perfilCliente,
        builder: (context, state) => const PerfilClienteScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      clienteRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(_AuthFalso()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.claro,
      routerConfig: router,
    ),
  );
}

/// Campo de la dirección (el primer campo de texto ahora es la búsqueda de
/// zona).
final _campoDireccion =
    find.widgetWithText(TextField, 'Av. Francisco de Miranda, Edificio…');

/// Corrección de la revisión: la zona se elige Municipio → Parroquia →
/// Urbanización. Libertador tiene una sola parroquia en estos datos, así que
/// se elige sola.
Future<void> _elegirSabanaGrande(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('zona-municipio')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Libertador').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('zona-urbanizacion')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sabana Grande').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-05: sin zona no guarda y avisa "Elige tu zona"', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // El selector de zona ocupa más alto: se asegura que el botón se vea.
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu zona'), findsOneWidget);
    expect(repo.ultimoZonaId, isNull);
  });

  testWidgets('HU-05: dirección de menos de 5 caracteres no guarda', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await _elegirSabanaGrande(tester);

    await tester.enterText(_campoDireccion, 'test');
    // El selector de zona ocupa más alto: se asegura que el botón se vea.
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe al menos 5 caracteres'), findsOneWidget);
    expect(repo.ultimoZonaId, isNull);
  });

  testWidgets('HU-05: guarda la zona y la dirección', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // Municipio → (parroquia sola, es la única) → urbanización.
    await _elegirSabanaGrande(tester);

    await tester.enterText(
        _campoDireccion, 'Av. Francisco de Miranda');
    // El selector de zona ocupa más alto: se asegura que el botón se vea.
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.ultimoZonaId, 1);
    expect(repo.ultimaDireccion, 'Av. Francisco de Miranda');
    // Al guardar vuelve a Mis solicitudes (no se queda en el formulario).
    expect(find.text('Inicio cliente'), findsOneWidget);
  });

  testWidgets('revisión: la zona se elige por municipio, parroquia y '
      'urbanización', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zona-municipio')), findsOneWidget);
    expect(find.byKey(const Key('zona-parroquia')), findsOneWidget);
    expect(find.byKey(const Key('zona-urbanizacion')), findsOneWidget);

    await _elegirSabanaGrande(tester);
    // La parroquia se completó sola (Libertador solo tiene El Recreo aquí).
    expect(find.text('El Recreo'), findsWidgets);
  });

  testWidgets('búsqueda: al escribir sugiere la urbanización y la elige',
      (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar-zona')), 'sabana');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('opcion-zona-1')));
    await tester.pumpAndSettle();

    await tester.enterText(_campoDireccion, 'Av. Francisco de Miranda');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.ultimoZonaId, 1);
  });
}
