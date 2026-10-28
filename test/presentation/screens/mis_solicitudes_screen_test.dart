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
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/mis_solicitudes_screen.dart';

class _RepositorioFalso implements SolicitudRepository {
  _RepositorioFalso({this.solicitudes = const []});

  final List<Solicitud> solicitudes;

  @override
  Future<List<Zona>> misZonas() async => const [];

  @override
  Future<List<SolicitudDisponible>> disponibles() async => const [];

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id-1';

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => null;

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => solicitudes;
}

class _ReputacionFalsa implements ReputacionRepository {
  const _ReputacionFalsa(this.promedio);

  final double? promedio;

  @override
  Future<double?> miPromedio() async => promedio;
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'cliente-1',
        rol: RolUsuario.cliente,
        nombre: 'Andrés Bello',
        perfilCompleto: true,
      );
}

Solicitud _solicitud({
  required String id,
  required EstadoSolicitud estado,
  required TipoLimpieza tipo,
  required DateTime inicio,
  required int numPostulantes,
  double pagoOfrecido = 30,
  String? trabajadoraNombre,
  double? trabajadoraPromedio,
}) {
  return Solicitud(
    id: id,
    clienteId: 'cliente-1',
    trabajadoraNombre: trabajadoraNombre,
    trabajadoraPromedio: trabajadoraPromedio,
    estado: estado,
    tipo: tipo,
    zonaId: 1,
    zona: 'Los Palos Grandes',
    inicio: inicio,
    horasEstimadas: 4,
    pagoOfrecido: pagoOfrecido,
    metodoPago: MetodoPago.pagoMovil,
    numPostulantes: numPostulantes,
    habitaciones: 2,
    banos: 1,
    tieneMascotas: false,
  );
}

Widget _app(
  _RepositorioFalso repositorio, {
  GoRouter? router,
  double? promedio = 4.9,
}) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repositorio),
      reputacionRepositoryProvider.overrideWithValue(
        _ReputacionFalsa(promedio),
      ),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: router != null
        ? MaterialApp.router(
            theme: AppTheme.claro,
            routerConfig: router,
          )
        : MaterialApp(
            theme: AppTheme.claro,
            home: const MisSolicitudesScreen(),
          ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets(
    'HU-08 c3: dado que no tengo solicitudes, muestra mensaje y botón para publicar',
    (tester) async {
      _pantallaGrande(tester);

      await tester.pumpWidget(_app(_RepositorioFalso(solicitudes: const [])));
      await tester.pumpAndSettle();

      // Criterio 3
      expect(find.text('Aún no tienes solicitudes'), findsOneWidget);
      expect(find.text('Publicar mi primera solicitud'), findsOneWidget);
      expect(find.text('Publicar solicitud'), findsOneWidget);
    },
  );

  testWidgets(
    'HU-08 c1: muestra solicitudes ordenadas por fecha del servicio con sus estados',
    (tester) async {
      _pantallaGrande(tester);

      final fecha1 = DateTime(2026, 11, 1, 9);
      final fecha2 = DateTime(2026, 11, 5, 8);
      final fecha3 = DateTime(2026, 11, 10, 14);
      final fecha4 = DateTime(2026, 11, 15, 10);

      final repo = _RepositorioFalso(
        solicitudes: [
          _solicitud(
            id: 's1',
            estado: EstadoSolicitud.publicada,
            tipo: TipoLimpieza.general,
            inicio: fecha1,
            numPostulantes: 2,
            pagoOfrecido: 30,
          ),
          _solicitud(
            id: 's2',
            estado: EstadoSolicitud.asignada,
            tipo: TipoLimpieza.profunda,
            inicio: fecha2,
            numPostulantes: 1,
            pagoOfrecido: 50,
            trabajadoraNombre: 'Ana Gómez',
            trabajadoraPromedio: 4.7,
          ),
          _solicitud(
            id: 's3',
            estado: EstadoSolicitud.completada,
            tipo: TipoLimpieza.planchado,
            inicio: fecha3,
            numPostulantes: 3,
            pagoOfrecido: 25,
          ),
          _solicitud(
            id: 's4',
            estado: EstadoSolicitud.cancelada,
            tipo: TipoLimpieza.postMudanza,
            inicio: fecha4,
            numPostulantes: 0,
            pagoOfrecido: 60,
          ),
        ],
      );

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      // Criterio 1: los 4 estados
      expect(find.text('Publicada'), findsOneWidget);
      expect(find.text('Asignada'), findsOneWidget);
      expect(find.text('Completada'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);

      // Tipos de limpieza
      expect(find.textContaining('Limpieza general'), findsWidgets);
      expect(find.textContaining('Limpieza profunda'), findsWidgets);
      expect(find.textContaining('Limpieza planchado'), findsWidgets);
      expect(find.textContaining('Limpieza post-mudanza'), findsWidgets);

      // Montos
      expect(find.textContaining(r'$30'), findsWidgets);
      expect(find.textContaining(r'$50'), findsWidgets);
      expect(find.textContaining(r'$25'), findsWidgets);
      expect(find.textContaining(r'$60'), findsWidgets);

      // Orden visual por fecha del servicio (criterio 1).
      final yGeneral = tester
          .getTopLeft(find.textContaining('Limpieza general'))
          .dy;
      final yProfunda = tester
          .getTopLeft(find.textContaining('Limpieza profunda'))
          .dy;
      final yPlanchado = tester
          .getTopLeft(find.textContaining('Limpieza planchado'))
          .dy;
      final yPostMudanza = tester
          .getTopLeft(find.textContaining('Limpieza post-mudanza'))
          .dy;
      expect(yGeneral, lessThan(yProfunda));
      expect(yProfunda, lessThan(yPlanchado));
      expect(yPlanchado, lessThan(yPostMudanza));

      // La trabajadora asignada sale de los datos, no está hardcodeada.
      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.text('★ 4,7'), findsOneWidget);
      expect(find.text('Carmen Pérez'), findsNothing);

      // El resumen usa a la trabajadora real y no duplica el punto.
      final resumen = tester.widget<Text>(find.textContaining('va a tu casa'));
      expect(
        resumen.data,
        'Ana Gómez va a tu casa el jueves a las 8:00 a. m. '
        'Y tu solicitud del domingo ya tiene 2 postulantes.',
      );
      expect(resumen.data, isNot(contains('..')));
    },
  );

  testWidgets('HU-08: muestra la calificación real del cliente o su ausencia', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(_app(_RepositorioFalso(), promedio: 4.6));
    await tester.pumpAndSettle();
    expect(find.text('★ Tu calificación: 4,6'), findsOneWidget);

    await tester.pumpWidget(_app(_RepositorioFalso(), promedio: null));
    await tester.pumpAndSettle();
    expect(find.text('★ Sin calificaciones aún'), findsOneWidget);
  });

  testWidgets(
    'HU-08 c2: muestra el número de postulantes cuando tiene postulaciones',
    (tester) async {
      _pantallaGrande(tester);

      final repo = _RepositorioFalso(
        solicitudes: [
          _solicitud(
            id: 's1',
            estado: EstadoSolicitud.publicada,
            tipo: TipoLimpieza.general,
            inicio: DateTime(2026, 11, 2, 9),
            numPostulantes: 3,
          ),
          _solicitud(
            id: 's2',
            estado: EstadoSolicitud.publicada,
            tipo: TipoLimpieza.profunda,
            inicio: DateTime(2026, 11, 3, 10),
            numPostulantes: 0,
          ),
        ],
      );

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      // Criterio 2: 3 postulantes en tarjeta y métrica
      expect(find.text('3 postulantes'), findsWidgets);
      expect(find.text('Sin postulantes aún'), findsOneWidget);
    },
  );

  testWidgets(
    'botón "Publicar mi primera solicitud" navega a /cliente/publicar',
    (tester) async {
      _pantallaGrande(tester);

      String? rutaDestino;
      final router = GoRouter(
        initialLocation: Rutas.inicioCliente,
        routes: [
          GoRoute(
            path: Rutas.inicioCliente,
            builder: (context, state) => const MisSolicitudesScreen(),
          ),
          GoRoute(
            path: Rutas.publicarSolicitud,
            builder: (context, state) {
              rutaDestino = Rutas.publicarSolicitud;
              return const Scaffold(body: Text('Pantalla Publicar'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _app(_RepositorioFalso(solicitudes: const []), router: router),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Publicar mi primera solicitud'));
      await tester.pumpAndSettle();

      expect(rutaDestino, Rutas.publicarSolicitud);
    },
  );

  testWidgets(
    'filtro interactivo por estado filtra solicitudes correctamente',
    (tester) async {
      _pantallaGrande(tester);

      final repo = _RepositorioFalso(
        solicitudes: [
          _solicitud(
            id: 's1',
            estado: EstadoSolicitud.publicada,
            tipo: TipoLimpieza.general,
            inicio: DateTime(2026, 11, 2, 9),
            numPostulantes: 3,
          ),
          _solicitud(
            id: 's2',
            estado: EstadoSolicitud.cancelada,
            tipo: TipoLimpieza.profunda,
            inicio: DateTime(2026, 11, 3, 10),
            numPostulantes: 0,
          ),
        ],
      );

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      // Inicialmente ambas se muestran
      expect(find.text('Publicada'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);

      // Filtramos por Canceladas
      await tester.tap(find.text('Canceladas'));
      await tester.pumpAndSettle();

      expect(find.text('Publicada'), findsNothing);
      expect(find.text('Cancelada'), findsOneWidget);

      // Restauramos Todas
      await tester.tap(find.text('Todas'));
      await tester.pumpAndSettle();

      expect(find.text('Publicada'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);
    },
  );

  testWidgets(
    'renderiza sin desbordamiento en pantalla móvil (390x844)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final repo = _RepositorioFalso(
        solicitudes: [
          _solicitud(
            id: 's1',
            estado: EstadoSolicitud.publicada,
            tipo: TipoLimpieza.general,
            inicio: DateTime(2026, 11, 2, 9),
            numPostulantes: 2,
          ),
          _solicitud(
            id: 's2',
            estado: EstadoSolicitud.asignada,
            tipo: TipoLimpieza.profunda,
            inicio: DateTime(2026, 11, 5, 8),
            numPostulantes: 1,
          ),
        ],
      );

      await tester.pumpWidget(_app(repo));
      await tester.pumpAndSettle();

      expect(find.text('Mis solicitudes'), findsWidgets);
      expect(find.text('Próximo servicio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
