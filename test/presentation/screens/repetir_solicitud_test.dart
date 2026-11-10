import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/quien_pone_productos.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/domain/services/solicitud_service.dart';
import 'package:limpiaya/presentation/providers/publicar_solicitud_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/publicar_solicitud_screen.dart';
import 'package:limpiaya/presentation/screens/cliente/tarjeta_solicitud_cliente.dart';

class _RepositorioFalso implements SolicitudRepository {
  _RepositorioFalso(this.anterior);

  final Solicitud? anterior;
  final publicadas = <NuevaSolicitud>[];
  final editadas = <String, NuevaSolicitud>{};

  @override
  Future<Solicitud?> miSolicitud(String id) async => anterior;

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async {
    publicadas.add(solicitud);
    return 'nueva';
  }

  @override
  Future<void> editar(String id, NuevaSolicitud datos) async =>
      editadas[id] = datos;

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

Solicitud _anterior({EstadoSolicitud estado = EstadoSolicitud.completada}) =>
    Solicitud(
      id: 's1',
      clienteId: 'c1',
      trabajadoraId: 't1',
      trabajadoraNombre: 'Carmen Pérez',
      estado: estado,
      tipo: TipoLimpieza.profunda,
      zonaId: 1,
      zona: 'Chacao',
      inicio: DateTime(2026, 10, 20, 8, 30),
      horasEstimadas: 5,
      pagoOfrecido: 45,
      metodoPago: MetodoPago.efectivoUsd,
      numPostulantes: 1,
      habitaciones: 3,
      banos: 2,
      tieneMascotas: true,
      productosPor: QuienPoneProductos.trabajadora,
      direccion: '4ta avenida, edificio Ávila',
      puntoReferencia: 'Frente a la panadería',
      notas: 'Tocar el timbre dos veces',
    );

Widget _app(_RepositorioFalso repo) {
  final router = GoRouter(
    initialLocation: Rutas.repetirSolicitud('s1'),
    routes: [
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
      GoRoute(
        path: Rutas.repetirSolicitudPatron,
        builder: (context, state) => PublicarSolicitudScreen(
          repetirDe: state.pathParameters['id'],
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repo),
      zonasCatalogoProvider.overrideWith(
        (ref) async => const [Zona(id: 1, nombre: 'Chacao')],
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

Widget _tarjeta(Solicitud solicitud, VoidCallback onRepetir) => MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TarjetaSolicitudCliente(
            solicitud: solicitud,
            onRepetir: onRepetir,
          ),
        ),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  test('HU-44 c1: se repiten las Completadas y Canceladas', () {
    expect(SolicitudService.sePuedeRepetir(_anterior()), isTrue);
    expect(
      SolicitudService.sePuedeRepetir(
        _anterior(estado: EstadoSolicitud.cancelada),
      ),
      isTrue,
    );
    expect(
      SolicitudService.sePuedeRepetir(
        _anterior(estado: EstadoSolicitud.publicada),
      ),
      isFalse,
    );
    expect(
      SolicitudService.sePuedeRepetir(
        _anterior(estado: EstadoSolicitud.asignada),
      ),
      isFalse,
    );
  });

  testWidgets('HU-44 c1: la tarjeta Completada y la Cancelada tienen '
      '"Repetir"', (tester) async {
    _pantallaGrande(tester);
    var veces = 0;

    await tester.pumpWidget(_tarjeta(_anterior(), () => veces++));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repetir-s1')));
    expect(veces, 1);

    await tester.pumpWidget(
      _tarjeta(_anterior(estado: EstadoSolicitud.cancelada), () => veces++),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repetir-s1')));
    expect(veces, 2);
  });

  testWidgets('HU-44: una solicitud Publicada no ofrece "Repetir"',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _tarjeta(_anterior(estado: EstadoSolicitud.publicada), () {}),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('repetir-s1')), findsNothing);
  });

  testWidgets('HU-44 c1: abre el formulario con los mismos datos y la fecha '
      'vacía', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(_anterior())));
    await tester.pumpAndSettle();

    expect(find.text('Repetir solicitud'), findsOneWidget);
    expect(find.text('4ta avenida, edificio Ávila'), findsOneWidget);
    expect(find.text('Elige la fecha'), findsOneWidget);
    expect(find.text('Fecha por elegir'), findsOneWidget);
    expect(find.text('Publicar solicitud'), findsOneWidget);
  });

  testWidgets('HU-44: sin fecha no se publica', (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(_anterior());
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Elige la fecha del servicio'), findsOneWidget);
    expect(repo.publicadas, isEmpty);
  });

  testWidgets('HU-44 c2: con la nueva fecha se crea una solicitud nueva y la '
      'anterior no cambia', (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(_anterior());
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // El calendario abre en mañana: se acepta ese día.
    await tester.tap(find.text('Elige la fecha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Publicar solicitud'));
    await tester.pumpAndSettle();

    expect(repo.editadas, isEmpty);
    expect(repo.publicadas, hasLength(1));
    final nueva = repo.publicadas.single;
    final manana = DateTime.now().add(const Duration(days: 1));
    expect(nueva.inicio.year, manana.year);
    expect(nueva.inicio.month, manana.month);
    expect(nueva.inicio.day, manana.day);
    // Misma hora y mismos datos que la anterior.
    expect(nueva.inicio.hour, 8);
    expect(nueva.inicio.minute, 30);
    expect(nueva.tipo, TipoLimpieza.profunda);
    expect(nueva.zonaId, 1);
    expect(nueva.direccion, '4ta avenida, edificio Ávila');
    expect(nueva.puntoReferencia, 'Frente a la panadería');
    expect(nueva.notas, 'Tocar el timbre dos veces');
    expect(nueva.horasEstimadas, 5);
    expect(nueva.pagoOfrecido, 45);
    expect(nueva.metodoPago, MetodoPago.efectivoUsd);
    expect(nueva.habitaciones, 3);
    expect(nueva.banos, 2);
    expect(nueva.tieneMascotas, isTrue);
    expect(nueva.productosPor, QuienPoneProductos.trabajadora);
    expect(find.text('Inicio'), findsOneWidget);
  });
}
