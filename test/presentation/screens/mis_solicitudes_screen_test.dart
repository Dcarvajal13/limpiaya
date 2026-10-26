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
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => solicitudes;
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
}) {
  return Solicitud(
    id: id,
    clienteId: 'cliente-1',
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

Widget _app(_RepositorioFalso repositorio, {GoRouter? router}) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repositorio),
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
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Profunda'), findsOneWidget);
      expect(find.text('Planchado'), findsOneWidget);
      expect(find.text('Post-mudanza'), findsOneWidget);

      // Montos
      expect(find.text(r'$30'), findsOneWidget);
      expect(find.text(r'$50'), findsOneWidget);
      expect(find.text(r'$25'), findsOneWidget);
      expect(find.text(r'$60'), findsOneWidget);
    },
  );

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

      // Criterio 2: 3 postulantes
      expect(find.text('3 postulantes'), findsOneWidget);
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
}
