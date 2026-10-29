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
import 'package:limpiaya/presentation/providers/publicar_solicitud_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/publicar_solicitud_screen.dart';

class _RepositorioFalso implements SolicitudRepository {
  _RepositorioFalso(this.solicitud);

  final Solicitud? solicitud;
  final editadas = <String, NuevaSolicitud>{};

  @override
  Future<Solicitud?> miSolicitud(String id) async => solicitud;

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
  Future<String> publicar(NuevaSolicitud solicitud) async => 'nueva';

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => const [];
}

Solicitud _solicitud({
  EstadoSolicitud estado = EstadoSolicitud.publicada,
  int postulantes = 2,
}) =>
    Solicitud(
      id: 's1',
      clienteId: 'c1',
      estado: estado,
      tipo: TipoLimpieza.general,
      zonaId: 1,
      zona: 'Chacao',
      // Siempre en el futuro, para que la validación de fecha pase.
      inicio: DateTime(DateTime.now().year + 1, 3, 14, 9),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: postulantes,
      habitaciones: 3,
      banos: 2,
      productosPor: QuienPoneProductos.cliente,
      direccion: '4ta avenida, edificio Ávila',
      puntoReferencia: 'Frente a la panadería',
    );

Widget _app(_RepositorioFalso repo) {
  final router = GoRouter(
    initialLocation: Rutas.editarSolicitud('s1'),
    routes: [
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => const Scaffold(body: Text('Inicio')),
      ),
      GoRoute(
        path: Rutas.editarSolicitudPatron,
        builder: (context, state) => PublicarSolicitudScreen(
          solicitudId: state.pathParameters['id'],
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

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('abre el formulario lleno con los datos de la solicitud',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(_solicitud())));
    await tester.pumpAndSettle();

    expect(find.text('Editar solicitud'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('4ta avenida, edificio Ávila'), findsOneWidget);
    expect(find.text('Las postulantes verán los datos nuevos'), findsOneWidget);
  });

  testWidgets('c1: guardar sin tocar fecha, hora ni pago no pide confirmar',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(_solicitud());
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('¿Guardar los cambios?'), findsNothing);
    expect(repo.editadas.keys, ['s1']);
    // Conserva el punto de referencia, que este formulario no muestra.
    expect(repo.editadas['s1']!.puntoReferencia, 'Frente a la panadería');
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('c3: con postulantes, cambiar el pago pide confirmar',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(_solicitud());
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '30'), '35');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('¿Guardar los cambios?'), findsOneWidget);
    expect(
      find.text('Ya tienes 2 postulantes. Verán la fecha, la hora o el pago '
          'nuevos.'),
      findsOneWidget,
    );

    // "Volver" no guarda nada.
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(repo.editadas, isEmpty);

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios').last);
    await tester.pumpAndSettle();
    expect(repo.editadas['s1']!.pagoOfrecido, 35);
  });

  testWidgets('sin postulantes, cambiar el pago no pide confirmar',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(_solicitud(postulantes: 0));
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '30'), '35');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('¿Guardar los cambios?'), findsNothing);
    expect(repo.editadas['s1']!.pagoOfrecido, 35);
  });

  testWidgets('c2: una solicitud Asignada no se puede editar', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      _RepositorioFalso(_solicitud(estado: EstadoSolicitud.asignada)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Esta solicitud ya no se puede editar'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsNothing);
  });
}
