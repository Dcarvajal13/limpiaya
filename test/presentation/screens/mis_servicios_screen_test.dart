import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/postulacion.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/mis_servicios_screen.dart';

class _RepositorioFalso implements PostulacionRepository {
  _RepositorioFalso(this.postulaciones);

  final List<Postulacion> postulaciones;

  @override
  Future<List<Postulacion>> misPostulaciones() async => postulaciones;
}

class _RepositorioConError implements PostulacionRepository {
  @override
  Future<List<Postulacion>> misPostulaciones() async =>
      throw Exception('sin red');
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'trabajadora-1',
        rol: RolUsuario.trabajadora,
        nombre: 'Carmen Pérez',
        perfilCompleto: true,
      );
}

Postulacion _postulacion(
  String id,
  EstadoPostulacion estado, {
  DateTime? inicio,
}) =>
    Postulacion(
      id: 'p-$id',
      solicitudId: 's-$id',
      estado: estado,
      tipo: TipoLimpieza.profunda,
      zona: 'Los Palos Grandes',
      inicio: inicio ?? DateTime(2026, 10, 24, 8, 30),
      horasEstimadas: 5,
      pagoOfrecido: 36,
      clienteNombre: 'María Alejandra',
    );

Widget _app(PostulacionRepository repo, {GoRouter? router}) {
  return ProviderScope(
    overrides: [
      postulacionRepositoryProvider.overrideWithValue(repo),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: router != null
        ? MaterialApp.router(theme: AppTheme.claro, routerConfig: router)
        : MaterialApp(theme: AppTheme.claro, home: const MisServiciosScreen()),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-13 c1: cada postulación se ve con su estado', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(
        _RepositorioFalso([
          _postulacion('1', EstadoPostulacion.pendiente),
          _postulacion('2', EstadoPostulacion.aceptada),
          _postulacion('3', EstadoPostulacion.noSeleccionada),
          _postulacion('4', EstadoPostulacion.solicitudCancelada),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('No seleccionada'), findsOneWidget);
    expect(find.text('Solicitud cancelada'), findsOneWidget);
    // Contador de la pestaña.
    expect(find.text('4'), findsOneWidget);
    // Datos reales, formato compacto (Figma W07 - Postulaciones).
    expect(find.textContaining('24 oct.'), findsWidgets);
    expect(find.textContaining('Recibes \$36'), findsWidgets);
    expect(find.textContaining('Los Palos Grandes'), findsWidgets);
    expect(find.text('Retirar postulación'), findsOneWidget);
  });

  testWidgets('HU-13 c3: tocar una aceptada lleva al servicio agendado',
      (tester) async {
    _pantallaGrande(tester);
    final router = GoRouter(
      initialLocation: Rutas.misServicios,
      routes: [
        GoRoute(
          path: Rutas.misServicios,
          builder: (context, state) => const MisServiciosScreen(),
        ),
        GoRoute(
          path: Rutas.servicioAgendadoPatron,
          builder: (context, state) => Scaffold(
            body: Text('Detalle ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _app(
        _RepositorioFalso([_postulacion('2', EstadoPostulacion.aceptada)]),
        router: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver servicio'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle s-2'), findsOneWidget);
  });

  testWidgets('HU-13 c3: las demás postulaciones no se abren', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(
        _RepositorioFalso([
          _postulacion('1', EstadoPostulacion.pendiente),
          _postulacion('3', EstadoPostulacion.noSeleccionada),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ver servicio'), findsNothing);
  });

  testWidgets('sin postulaciones muestra mensaje y botón a los trabajos',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(const [])));
    await tester.pumpAndSettle();

    expect(find.text('Aún no te has postulado a ningún trabajo'),
        findsOneWidget);
    expect(find.text('Ver trabajos disponibles'), findsOneWidget);
  });

  testWidgets('si falla la carga permite reintentar', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioConError()));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('las pestañas Próximos y Pasados avisan que llegarán pronto',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(const [])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Próximos'));
    await tester.pumpAndSettle();
    expect(find.text('Tus próximos servicios'), findsOneWidget);

    await tester.tap(find.text('Pasados'));
    await tester.pumpAndSettle();
    expect(find.text('Tus servicios pasados'), findsOneWidget);
  });

  testWidgets('renderiza sin desbordamiento en móvil (390x844)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        _RepositorioFalso([
          _postulacion('1', EstadoPostulacion.pendiente),
          _postulacion('2', EstadoPostulacion.aceptada),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis servicios'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
