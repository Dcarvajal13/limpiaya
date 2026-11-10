import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/postulacion.dart';
import 'package:limpiaya/domain/entities/postulante.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/postulantes_screen.dart';

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas([this.postulantes = const []]);

  final List<Postulante> postulantes;

  @override
  Future<List<Postulante>> postulantesDe(String solicitudId) async =>
      postulantes;

  @override
  Future<List<Postulacion>> misPostulaciones() async => const [];

  @override
  Future<void> postular({required String solicitudId, String? mensaje}) async {}

  @override
  Future<void> retirar(String postulacionId) async {}
}

/// Solo devuelve una solicitud del cliente, para el resumen de arriba.
class _SolicitudesFalsas implements SolicitudRepository {
  @override
  Future<List<Solicitud>> misSolicitudes() async => [
        Solicitud(
          id: 's1',
          clienteId: 'c1',
          estado: EstadoSolicitud.publicada,
          tipo: TipoLimpieza.general,
          zonaId: 1,
          zona: 'Petare',
          inicio: DateTime(2026, 10, 30, 12),
          horasEstimadas: 3,
          pagoOfrecido: 30,
          metodoPago: MetodoPago.pagoMovil,
          numPostulantes: 2,
        ),
      ];

  @override
  Future<List<Zona>> misZonas() async => const [];

  @override
  Future<List<SolicitudDisponible>> disponibles() async => const [];

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => null;

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id';

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<void> cancelar(String id, {String? motivo}) async {}

  @override
  Future<Solicitud?> miSolicitud(String id) async => null;

  @override
  Future<void> editar(String id, NuevaSolicitud datos) async {}
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'c1',
        rol: RolUsuario.cliente,
        nombre: 'María Alejandra',
        perfilCompleto: true,
      );
}

Widget _app(_PostulacionesFalsas repo) => ProviderScope(
      overrides: [
        postulacionRepositoryProvider.overrideWithValue(repo),
        solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas()),
        sesionProvider.overrideWith(_SesionFalsa.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const PostulantesScreen(solicitudId: 's1'),
      ),
    );

Widget _appConRutas(_PostulacionesFalsas repo) {
  final router = GoRouter(
    initialLocation: Rutas.postulantes('s1'),
    routes: [
      GoRoute(
        path: Rutas.postulantesPatron,
        builder: (context, state) =>
            PostulantesScreen(solicitudId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Rutas.perfilPublicoTrabajadoraPatron,
        builder: (context, state) => Scaffold(
          body: Text('Perfil ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      postulacionRepositoryProvider.overrideWithValue(repo),
      solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas()),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-14 c3: sin postulantes muestra el aviso', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_PostulacionesFalsas()));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay postulantes'), findsOneWidget);
  });

  testWidgets('H6: muestra el resumen de la solicitud', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_PostulacionesFalsas()));
    await tester.pumpAndSettle();

    expect(find.text('TU SOLICITUD'), findsOneWidget);
    expect(find.textContaining('Petare'), findsOneWidget);
  });

  testWidgets('HU-14 c4: tocar una postulante abre su perfil público',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _appConRutas(
        _PostulacionesFalsas([
          Postulante(
            postulacionId: 'p1',
            trabajadoraId: 't1',
            nombre: 'Carmen Pérez',
            estado: EstadoPostulacion.pendiente,
            fecha: DateTime(2026, 10, 25),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Carmen Pérez'));
    await tester.pumpAndSettle();

    expect(find.text('Perfil t1'), findsOneWidget);
  });

  testWidgets('HU-14 c1: muestra nombre, reputación, insignia, experiencia y '
      'mensaje', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(
        _PostulacionesFalsas([
          Postulante(
            postulacionId: 'p1',
            trabajadoraId: 't1',
            nombre: 'Carmen Pérez',
            estado: EstadoPostulacion.pendiente,
            fecha: DateTime(2026, 10, 25),
            promedio: 4.8,
            totalResenas: 3,
            experienciaAnios: 5,
            serviciosCompletados: 12,
            mensaje: 'Tengo 15 años de experiencia.',
          ),
          Postulante(
            postulacionId: 'p2',
            trabajadoraId: 't2',
            nombre: 'Marisol Gómez',
            estado: EstadoPostulacion.pendiente,
            fecha: DateTime(2026, 10, 26),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 trabajadoras se postularon'), findsOneWidget);
    expect(find.text('Carmen Pérez'), findsOneWidget);
    expect(find.text('★ 4,8 · 3 reseñas'), findsOneWidget);
    expect(find.text('Nueva en la plataforma'), findsOneWidget);
    expect(find.text('Identidad verificada'), findsNWidgets(2));
    expect(
      find.text('5 años de experiencia · 12 servicios completados'),
      findsOneWidget,
    );
    expect(find.text('“Tengo 15 años de experiencia.”'), findsOneWidget);
    expect(find.text('No dejó un mensaje.'), findsOneWidget);
  });
}