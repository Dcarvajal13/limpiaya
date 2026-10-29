import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/postulacion.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/domain/services/postulacion_service.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/solicitudes_disponibles_screen.dart';

class _SolicitudesFalsas implements SolicitudRepository {
  @override
  Future<Solicitud?> miSolicitud(String id) async => null;

  @override
  Future<void> editar(String id, NuevaSolicitud datos) async {}

  @override
  Future<void> cancelar(String id, {String? motivo}) async {}

  @override
  Future<List<Zona>> misZonas() async => const [
    Zona(id: 1, nombre: 'Chacao (casco)'),
  ];

  @override
  Future<List<SolicitudDisponible>> disponibles() async => [
    SolicitudDisponible(
      id: 's1',
      tipo: TipoLimpieza.general,
      zonaId: 1,
      zona: 'Chacao (casco)',
      inicio: DateTime.now().add(const Duration(days: 3)),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 0,
    ),
  ];

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id-de-prueba';

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => null;

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => const [];
}

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas({this.existentes = const [], this.error});

  /// Postulaciones que ya tiene la trabajadora (HU-12 c2).
  final List<Postulacion> existentes;

  /// Si viene, `postular()` falla con este mensaje (HU-12 c3).
  final String? error;

  final llamadas = <({String solicitudId, String? mensaje})>[];

  @override
  Future<List<Postulacion>> misPostulaciones() async => existentes;

  @override
  Future<void> retirar(String postulacionId) async {}

  @override
  Future<void> postular({
    required String solicitudId,
    String? mensaje,
  }) async {
    llamadas.add((solicitudId: solicitudId, mensaje: mensaje));
    if (error != null) throw AppException(error!);
  }
}

class _ReputacionFalsa implements ReputacionRepository {
  const _ReputacionFalsa();

  @override
  Future<double?> miPromedio() async => 4.9;
}

class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this.verificacion);

  final String? verificacion;

  @override
  Future<Sesion?> build() async => Sesion(
    id: 'u1',
    rol: RolUsuario.trabajadora,
    nombre: 'Carmen Pérez',
    perfilCompleto: true,
    verificacion: verificacion,
  );
}

Widget _app(
  PostulacionRepository postulaciones, {
  String? verificacion = 'aprobada',
}) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas()),
      postulacionRepositoryProvider.overrideWithValue(postulaciones),
      reputacionRepositoryProvider.overrideWithValue(const _ReputacionFalsa()),
      sesionProvider.overrideWith(() => _SesionFalsa(verificacion)),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const SolicitudesDisponiblesScreen(),
    ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Postulacion _postulacionA() => Postulacion(
  id: 'p1',
  solicitudId: 's1',
  estado: EstadoPostulacion.pendiente,
  tipo: TipoLimpieza.general,
  zona: 'Chacao (casco)',
  inicio: DateTime.now().add(const Duration(days: 3)),
  horasEstimadas: 4,
  pagoOfrecido: 30,
);

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-12 c1: se postula con un mensaje y confirma', (tester) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas();

    await tester.pumpWidget(_app(postulaciones));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postularme-s1')));
    await tester.pumpAndSettle();

    expect(find.text('Postularme'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('campo-mensaje-postulacion')),
      'Tengo experiencia con casas grandes',
    );
    await tester.tap(find.byKey(const Key('enviar-postulacion')));
    await tester.pumpAndSettle();

    expect(postulaciones.llamadas, hasLength(1));
    expect(postulaciones.llamadas.single.solicitudId, 's1');
    expect(
      postulaciones.llamadas.single.mensaje,
      'Tengo experiencia con casas grandes',
    );
    expect(find.text(PostulacionService.mensajeEnviada), findsOneWidget);
  });

  testWidgets('HU-12 c1: el mensaje es opcional', (tester) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas();

    await tester.pumpWidget(_app(postulaciones));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postularme-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enviar-postulacion')));
    await tester.pumpAndSettle();

    expect(postulaciones.llamadas.single.mensaje, isEmpty);
  });

  testWidgets('HU-12 c2: si ya me postulé el botón queda apagado', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas(
      existentes: [_postulacionA()],
    );

    await tester.pumpWidget(_app(postulaciones));
    await tester.pumpAndSettle();

    expect(find.text('Ya te postulaste'), findsOneWidget);
    final boton = tester.widget<FilledButton>(
      find.byKey(const Key('postularme-s1')),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('HU-12 c3: avisa el choque de horario y no cierra', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas(
      error: PostulacionService.mensajeSolape,
    );

    await tester.pumpWidget(_app(postulaciones));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postularme-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enviar-postulacion')));
    await tester.pumpAndSettle();

    expect(find.text(PostulacionService.mensajeSolape), findsOneWidget);
    // El diálogo sigue abierto para que pueda corregir o cancelar.
    expect(find.byKey(const Key('campo-mensaje-postulacion')), findsOneWidget);
  });

  testWidgets('HU-12 c4: sin identidad verificada no postula y ofrece HU-21', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas();

    await tester.pumpWidget(_app(postulaciones, verificacion: 'en_revision'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postularme-s1')));
    await tester.pumpAndSettle();

    expect(
      find.text(PostulacionService.mensajeVerificacion),
      findsOneWidget,
    );
    expect(find.byKey(const Key('ir-a-verificacion')), findsOneWidget);
    expect(postulaciones.llamadas, isEmpty);
  });
}
