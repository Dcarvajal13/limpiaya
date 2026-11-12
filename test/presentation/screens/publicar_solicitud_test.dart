import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/publicar_solicitud_provider.dart';
import 'package:limpiaya/domain/entities/direccion_guardada.dart';
import 'package:limpiaya/presentation/screens/cliente/publicar_solicitud_screen.dart';

import '../../helpers/direcciones_falsas.dart';

class _RepositorioFalso implements SolicitudRepository {
  final publicadas = <NuevaSolicitud>[];

  @override
  Future<Solicitud?> miSolicitud(String id) async => null;

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async {
    publicadas.add(solicitud);
    return 's1';
  }

  @override
  Future<void> editar(String id, NuevaSolicitud datos) async {}

  @override
  Future<void> cancelar(String id, {String? motivo}) async {}

  @override
  Future<List<Zona>> misZonas() async => const [];

  @override
  Future<List<SolicitudDisponible>> disponibles() async => const [];

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => null;

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => const [];
}

Widget _app(_RepositorioFalso repo, {DireccionesFalsas? direcciones}) {
  final router = GoRouter(
    initialLocation: Rutas.publicarSolicitud,
    routes: [
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
      GoRoute(
        path: Rutas.publicarSolicitud,
        builder: (context, state) => const PublicarSolicitudScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repo),
      direccionesRepositoryProvider.overrideWithValue(
        direcciones ?? DireccionesFalsas(),
      ),
      zonasCatalogoProvider.overrideWith(
        (ref) async => const [
          Zona(id: 1, nombre: 'Altamira', municipio: 'Chacao', parroquia: 'Chacao'),
        ],
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets(
      'al intentar publicar sin completar datos obligatorios, muestra aviso interactivo y lista campos faltantes',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // El formulario empieza sin zona, sin dirección y sin indicar quién pone los productos.
    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    // 1. No se envía la solicitud
    expect(repo.publicadas, isEmpty);

    // 2. Muestra el bloque interactivo de datos obligatorios en la vista previa
    expect(find.text('Faltan datos obligatorios:'), findsOneWidget);
    expect(find.text('Zona o urbanización'), findsOneWidget);
    expect(find.text('Dirección completa'), findsOneWidget);
    expect(find.text('Quién pone los productos'), findsOneWidget);

    // 3. Muestra el SnackBar flotante de advertencia
    expect(find.byType(SnackBar), findsOneWidget);

    // 4. Muestra la indicación en rojo en la vista previa y en la validación del selector
    expect(find.text('Elige una zona'), findsNWidgets(2));

    // 5. Tocar en el chip interactivo de la vista previa no revienta y permite interactuar
    await tester.tap(find.text('Quién pone los productos'));
    await tester.pumpAndSettle();
  });

  testWidgets('direcciones guardadas: llega con "Casa" y cambia con un toque',
      (tester) async {
    _pantallaGrande(tester);
    final direcciones = DireccionesFalsas(const [
      DireccionGuardada(
        id: 'casa',
        nombre: 'Casa',
        zonaId: 1,
        zona: 'Altamira',
        direccion: 'Av. Luis Roche, Edificio Sol',
      ),
      DireccionGuardada(
        id: 'mama',
        nombre: 'Casa de mamá',
        zonaId: 1,
        zona: 'Altamira',
        direccion: '3ra transversal, Quinta Mery',
        puntoReferencia: 'Frente a la plaza',
      ),
    ]);
    await tester.pumpWidget(_app(_RepositorioFalso(), direcciones: direcciones));
    await tester.pumpAndSettle();

    // La primera dirección guardada viene precargada.
    expect(find.text('Tus direcciones'), findsOneWidget);
    expect(find.text('Av. Luis Roche, Edificio Sol'), findsOneWidget);

    await tester.tap(find.byKey(const Key('usar-direccion-mama')));
    await tester.pumpAndSettle();

    expect(find.text('3ra transversal, Quinta Mery'), findsOneWidget);
    expect(find.text('Av. Luis Roche, Edificio Sol'), findsNothing);
    // Es una dirección guardada: no ofrece guardarla otra vez.
    expect(find.byKey(const Key('guardar-direccion-nueva')), findsNothing);
  });

  testWidgets('"Otra dirección" vacía el lugar para escribir una nueva',
      (tester) async {
    _pantallaGrande(tester);
    final direcciones = DireccionesFalsas(const [
      DireccionGuardada(
        id: 'casa',
        nombre: 'Casa',
        zonaId: 1,
        direccion: 'Av. Luis Roche, Edificio Sol',
      ),
    ]);
    await tester.pumpWidget(_app(_RepositorioFalso(), direcciones: direcciones));
    await tester.pumpAndSettle();

    expect(find.text('Av. Luis Roche, Edificio Sol'), findsOneWidget);

    await tester.tap(find.byKey(const Key('otra-direccion')));
    await tester.pumpAndSettle();

    expect(find.text('Av. Luis Roche, Edificio Sol'), findsNothing);
    // Sin zona todavía, no ofrece guardarla.
    expect(find.byKey(const Key('guardar-direccion-nueva')), findsNothing);
  });
}
