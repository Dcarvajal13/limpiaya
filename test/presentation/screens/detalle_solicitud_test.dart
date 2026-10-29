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
import 'package:limpiaya/domain/entities/quien_pone_productos.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/domain/services/postulacion_service.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/detalle_solicitud_screen.dart';

SolicitudDisponible _solicitud() => SolicitudDisponible(
  id: 's1',
  tipo: TipoLimpieza.profunda,
  zonaId: 1,
  zona: 'Chacao (casco)',
  inicio: DateTime(2026, 10, 29, 9),
  horasEstimadas: 4,
  pagoOfrecido: 30,
  metodoPago: MetodoPago.pagoMovil,
  numPostulantes: 3,
  habitaciones: 2,
  banos: 1,
  productosPor: QuienPoneProductos.trabajadora,
);

class _SolicitudesFalsas implements SolicitudRepository {
  @override
  Future<Solicitud?> miSolicitud(String id) async => null;

  @override
  Future<void> editar(String id, NuevaSolicitud datos) async {}

  @override
  Future<void> cancelar(String id, {String? motivo}) async {}

  _SolicitudesFalsas({this.detalle});

  /// Lo que devuelve `solicitudDisponible(id)`; null = ya no está.
  final SolicitudDisponible? detalle;

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => detalle;

  @override
  Future<List<SolicitudDisponible>> disponibles() async => const [];

  @override
  Future<List<Zona>> misZonas() async => const [Zona(id: 1, nombre: 'Chacao')];

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id';

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Solicitud>> misSolicitudes() async => const [];
}

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas({this.existentes = const [], this.error});

  final List<Postulacion> existentes;

  /// Si viene, `postular()` falla con este mensaje (HU-45 c3).
  final String? error;

  final llamadas = <String>[];

  @override
  Future<List<Postulacion>> misPostulaciones() async => existentes;

  @override
  Future<void> postular({
    required String solicitudId,
    String? mensaje,
  }) async {
    llamadas.add(solicitudId);
    if (error != null) throw AppException(error!);
  }

  @override
  Future<void> retirar(String postulacionId) async {}
}

class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this.verificacion);

  final String? verificacion;

  @override
  Future<Sesion?> build() async => Sesion(
    id: 'trabajadora-1',
    rol: RolUsuario.trabajadora,
    nombre: 'Carmen Pérez',
    perfilCompleto: true,
    verificacion: verificacion,
  );
}

Widget _app({
  SolicitudDisponible? detalle,
  PostulacionRepository? postulaciones,
  String? verificacion = 'aprobada',
}) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(
        _SolicitudesFalsas(detalle: detalle ?? _solicitud()),
      ),
      postulacionRepositoryProvider.overrideWithValue(
        postulaciones ?? _PostulacionesFalsas(),
      ),
      sesionProvider.overrideWith(() => _SesionFalsa(verificacion)),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const DetalleSolicitudScreen(solicitudId: 's1'),
    ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-45 c1: muestra fecha, hora, horas, tipo, zona, pago y '
      'método de pago', (tester) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Jueves 29 de octubre'), findsOneWidget);
    expect(find.text('9:00 a. m.'), findsOneWidget);
    expect(find.text('4 horas'), findsOneWidget);
    expect(find.text('Profunda'), findsWidgets);
    expect(find.text('Chacao (casco), Caracas'), findsOneWidget);
    expect(find.text(r'Recibes $30'), findsOneWidget);
    expect(find.text('Pago Móvil'), findsOneWidget);
    expect(find.text('3 postulantes'), findsOneWidget);
    // Los detalles de la vivienda (HU-43) siguen a la vista.
    expect(find.text('2 hab.'), findsOneWidget);
    expect(find.text('1 baño'), findsOneWidget);
    expect(find.text('Los pones tú'), findsOneWidget);
  });

  testWidgets('HU-45 c2: no muestra la dirección exacta del cliente', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.text('La dirección exacta la verás cuando el cliente te elija.'),
      findsOneWidget,
    );
    // La vista pública ni siquiera trae la dirección: nada del domicilio del
    // cliente puede aparecer en pantalla.
    expect(find.textContaining('Calle'), findsNothing);
    expect(find.textContaining('Av.'), findsNothing);
  });

  testWidgets('HU-45 c3: si ya no está disponible, avisa al postularse', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas(
      error: PostulacionService.mensajeNoDisponible,
    );

    await tester.pumpWidget(_app(postulaciones: postulaciones));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('postularme-detalle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enviar-postulacion')));
    await tester.pumpAndSettle();

    expect(postulaciones.llamadas, ['s1']);
    expect(
      find.text(PostulacionService.mensajeNoDisponible),
      findsOneWidget,
    );
  });

  testWidgets('HU-12 c2: si ya me postulé el botón queda apagado', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final postulaciones = _PostulacionesFalsas(
      existentes: [
        Postulacion(
          id: 'p1',
          solicitudId: 's1',
          estado: EstadoPostulacion.pendiente,
          tipo: TipoLimpieza.profunda,
          zona: 'Chacao (casco)',
          inicio: DateTime(2026, 10, 29, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
        ),
      ],
    );

    await tester.pumpWidget(_app(postulaciones: postulaciones));
    await tester.pumpAndSettle();

    final boton = tester.widget<FilledButton>(
      find.byKey(const Key('postularme-detalle')),
    );
    expect(boton.onPressed, isNull);
    expect(find.text('Ya te postulaste'), findsOneWidget);
  });

  testWidgets('si la solicitud ya no existe, invita a ver otros trabajos', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          solicitudRepositoryProvider.overrideWithValue(
            _SolicitudesFalsas(),
          ),
          postulacionRepositoryProvider.overrideWithValue(
            _PostulacionesFalsas(),
          ),
          sesionProvider.overrideWith(() => _SesionFalsa('aprobada')),
        ],
        child: const MaterialApp(
          home: DetalleSolicitudScreen(solicitudId: 's1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Esta solicitud ya no está disponible'),
      findsOneWidget,
    );
  });

  testWidgets('revisión: en escritorio el pago va en una columna a la derecha',
      (tester) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('LO QUE RECIBES'), findsOneWidget);
    expect(find.text('Limpieza profunda en Chacao (casco)'), findsOneWidget);
    final pago = tester.getTopLeft(find.text('LO QUE RECIBES'));
    final cuando = tester.getTopRight(find.text('Cuándo'));
    expect(pago.dx, greaterThan(cuando.dx));
    // El botón está en la misma columna que el pago.
    final boton = tester.getTopLeft(find.byKey(const Key('postularme-detalle')));
    expect((boton.dx - pago.dx).abs(), lessThan(40));
  });

  testWidgets('revisión: la página trae más contexto para decidir', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Termina cerca de la 1:00 p. m.'), findsOneWidget);
    expect(find.text(r'$7.50 por hora'), findsOneWidget);
    expect(find.text('Antes de postularte'), findsOneWidget);
    // Lleva sus productos: se le recuerda.
    expect(
      find.text('En este trabajo llevas tú los productos de limpieza.'),
      findsOneWidget,
    );
  });

  testWidgets('revisión: en móvil queda en una columna sin desbordes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('LO QUE RECIBES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
