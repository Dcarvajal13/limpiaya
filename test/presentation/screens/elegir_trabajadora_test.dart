import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
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
import 'package:limpiaya/domain/repositories/servicio_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/postulantes_screen.dart';
import 'package:limpiaya/presentation/screens/trabajadora/tarjeta_postulacion.dart';

/// Datos compartidos entre los repositorios falsos: lo que hace uno (elegir)
/// lo ve el otro (la lista de postulantes), como pasaría con la base real.
class _Datos {
  _Datos(this.postulantes, {this.estado = EstadoSolicitud.publicada});

  List<Postulante> postulantes;
  EstadoSolicitud estado;
  final elegidas = <String>[];
  String? error;
}

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<List<Postulante>> postulantesDe(String solicitudId) async =>
      datos.postulantes;

  @override
  Future<List<Postulacion>> misPostulaciones() async => const [];

  @override
  Future<void> postular({required String solicitudId, String? mensaje}) async {}

  @override
  Future<void> retirar(String postulacionId) async {}
}

/// Hace lo mismo que `elegir_trabajadora`: la elegida queda Aceptada y las
/// demás pendientes salen de la lista (No seleccionada).
class _ServiciosFalsos implements ServicioRepository {
  _ServiciosFalsos(this.datos);

  final _Datos datos;

  @override
  Future<void> elegir(String postulacionId) async {
    if (datos.error != null) throw AppException(datos.error!);
    datos.elegidas.add(postulacionId);
    datos.estado = EstadoSolicitud.asignada;
    datos.postulantes = [
      for (final p in datos.postulantes)
        if (p.postulacionId == postulacionId) _postulante(
          p.postulacionId,
          p.nombre,
          estado: EstadoPostulacion.aceptada,
        ),
    ];
  }

  @override
  Future<void> completar(String solicitudId) async {}
}

class _SolicitudesFalsas implements SolicitudRepository {
  _SolicitudesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<List<Solicitud>> misSolicitudes() async => [
        Solicitud(
          id: 's1',
          clienteId: 'c1',
          estado: datos.estado,
          tipo: TipoLimpieza.general,
          zonaId: 1,
          zona: 'Petare',
          inicio: DateTime(2026, 11, 14, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
          metodoPago: MetodoPago.pagoMovil,
          numPostulantes: datos.postulantes.length,
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

Postulante _postulante(
  String id,
  String nombre, {
  EstadoPostulacion estado = EstadoPostulacion.pendiente,
}) =>
    Postulante(
      postulacionId: id,
      trabajadoraId: 't-$id',
      nombre: nombre,
      estado: estado,
      fecha: DateTime(2026, 11, 8),
    );

Widget _app(_Datos datos) => ProviderScope(
      overrides: [
        postulacionRepositoryProvider
            .overrideWithValue(_PostulacionesFalsas(datos)),
        solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas(datos)),
        servicioRepositoryProvider.overrideWithValue(_ServiciosFalsos(datos)),
        sesionProvider.overrideWith(_SesionFalsa.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const PostulantesScreen(solicitudId: 's1'),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-15: cada postulante pendiente ofrece "Elegir"',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_Datos([
        _postulante('p1', 'Carmen Pérez'),
        _postulante('p2', 'Marisol Gómez'),
      ])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegir a Carmen'), findsOneWidget);
    expect(find.text('Elegir a Marisol'), findsOneWidget);
  });

  testWidgets('HU-15: con "No" no se elige a nadie', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos([_postulante('p1', 'Carmen Pérez')]);
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('elegir-p1')));
    await tester.pumpAndSettle();
    expect(find.text('¿Elegir a Carmen Pérez?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancelar-elegir')));
    await tester.pumpAndSettle();

    expect(datos.elegidas, isEmpty);
    expect(find.text('Elegir a Carmen'), findsOneWidget);
  });

  testWidgets('HU-15 c1, c2 y c4: al confirmar queda elegida, las demás '
      'salen y ya no se puede elegir', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos([
      _postulante('p1', 'Carmen Pérez'),
      _postulante('p2', 'Marisol Gómez'),
    ]);
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('elegir-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-elegir')));
    await tester.pumpAndSettle();

    expect(datos.elegidas, ['p1']);
    expect(
      find.text('Elegiste a Carmen Pérez. El servicio quedó agendado.'),
      findsOneWidget,
    );
    // c1: el resumen ya dice Asignada y la tarjeta, Elegida.
    expect(find.text('Asignada'), findsOneWidget);
    expect(find.text('Elegida'), findsOneWidget);
    expect(find.text('Trabajadora elegida'), findsOneWidget);
    // c2: la otra ya no aparece.
    expect(find.text('Marisol Gómez'), findsNothing);
    // c4: ningún botón "Elegir".
    expect(find.textContaining('Elegir a'), findsNothing);
  });

  testWidgets('HU-15 c4: si la solicitud ya está Asignada no hay "Elegir"',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_Datos(
        [_postulante('p1', 'Carmen Pérez', estado: EstadoPostulacion.aceptada)],
        estado: EstadoSolicitud.asignada,
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegida'), findsOneWidget);
    expect(find.textContaining('Elegir a'), findsNothing);
  });

  testWidgets('HU-15: si la base lo rechaza muestra el motivo', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos([_postulante('p1', 'Carmen Pérez')])
      ..error = 'Esta trabajadora ya tiene un servicio en ese horario';
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('elegir-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-elegir')));
    await tester.pumpAndSettle();

    expect(
      find.text('Esta trabajadora ya tiene un servicio en ese horario'),
      findsOneWidget,
    );
    expect(find.text('Elegir a Carmen'), findsOneWidget);
  });

  group('HU-15 c3: la trabajadora elegida ve la dirección', () {
    Postulacion postulacion(EstadoPostulacion estado) => Postulacion(
          id: 'p1',
          solicitudId: 's1',
          estado: estado,
          tipo: TipoLimpieza.general,
          zona: 'Petare',
          inicio: DateTime(2026, 11, 14, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
          direccion: 'Calle 1, casa 2',
          puntoReferencia: 'Frente a la plaza',
        );

    Widget tarjeta(Postulacion p) => MaterialApp(
          theme: AppTheme.claro,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TarjetaPostulacion(postulacion: p),
            ),
          ),
        );

    testWidgets('aceptada: muestra dirección y punto de referencia',
        (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        tarjeta(postulacion(EstadoPostulacion.aceptada)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Calle 1, casa 2 · Ref.: Frente a la plaza'),
        findsOneWidget,
      );
    });

    testWidgets('pendiente: no la muestra', (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        tarjeta(postulacion(EstadoPostulacion.pendiente)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Calle 1'), findsNothing);
    });
  });
}
