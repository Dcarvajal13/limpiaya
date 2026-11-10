import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
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
import 'package:limpiaya/domain/entities/servicio_agendado.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/servicio_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/mis_solicitudes_screen.dart';
import 'package:limpiaya/presentation/screens/trabajadora/mis_servicios_screen.dart';

// --- Lado del cliente ------------------------------------------------------

/// Solicitudes del cliente que cambian cuando el servicio falso cancela.
class _Datos {
  _Datos(this.solicitudes);

  List<Solicitud> solicitudes;
  final canceladas = <String, String>{};
}

class _SolicitudesFalsas implements SolicitudRepository {
  _SolicitudesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<List<Solicitud>> misSolicitudes() async => datos.solicitudes;

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

/// Hace lo mismo que `cancelar_servicio`: queda Cancelada, con el motivo y
/// quién la canceló (aquí, el cliente c1).
class _ServiciosFalsos implements ServicioRepository {
  _ServiciosFalsos([this.datos]);

  final _Datos? datos;
  final canceladas = <String, String>{};

  @override
  Future<void> elegir(String postulacionId) async {}

  @override
  Future<void> completar(String solicitudId) async {}

  @override
  Future<List<ServicioAgendado>> misServicios() async => const [];

  @override
  Future<ServicioAgendado?> servicioAgendado(String id) async => null;

  @override
  Future<void> cancelar(String solicitudId, {required String motivo}) async {
    canceladas[solicitudId] = motivo;
    final d = datos;
    if (d == null) return;
    d.solicitudes = [
      for (final s in d.solicitudes)
        s.id == solicitudId
            ? _solicitud(
                s.id,
                EstadoSolicitud.cancelada,
                motivo: motivo,
                canceladaPor: 'c1',
              )
            : s,
    ];
  }
}

class _ReputacionFalsa implements ReputacionRepository {
  @override
  Future<double?> miPromedio() async => null;
}

class _SesionCliente extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'c1',
        rol: RolUsuario.cliente,
        nombre: 'María Alejandra',
        perfilCompleto: true,
      );
}

Solicitud _solicitud(
  String id,
  EstadoSolicitud estado, {
  String? motivo,
  String? canceladaPor,
}) =>
    Solicitud(
      id: id,
      clienteId: 'c1',
      trabajadoraId: 't1',
      trabajadoraNombre: 'Carmen Pérez',
      estado: estado,
      tipo: TipoLimpieza.general,
      zonaId: 1,
      zona: 'Petare',
      inicio: DateTime.now().add(const Duration(days: 3)),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 1,
      motivoCancelacion: motivo,
      canceladaPor: canceladaPor,
    );

Widget _appCliente(_Datos datos, _ServiciosFalsos servicios) => ProviderScope(
      overrides: [
        solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas(datos)),
        servicioRepositoryProvider.overrideWithValue(servicios),
        reputacionRepositoryProvider.overrideWithValue(_ReputacionFalsa()),
        sesionProvider.overrideWith(_SesionCliente.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const MisSolicitudesScreen(),
      ),
    );

// --- Lado de la trabajadora ------------------------------------------------

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas(this.postulaciones);

  final List<Postulacion> postulaciones;

  @override
  Future<List<Postulacion>> misPostulaciones() async => postulaciones;

  @override
  Future<void> retirar(String postulacionId) async {}

  @override
  Future<List<Postulante>> postulantesDe(String solicitudId) async => const [];

  @override
  Future<void> postular({required String solicitudId, String? mensaje}) async {}
}

class _SesionTrabajadora extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 't1',
        rol: RolUsuario.trabajadora,
        nombre: 'Carmen Pérez',
        perfilCompleto: true,
      );
}

Postulacion _postulacion(
  String id,
  EstadoPostulacion estado,
  EstadoSolicitud estadoSolicitud, {
  String? motivo,
  bool canceladaPorMi = false,
}) =>
    Postulacion(
      id: 'p-$id',
      solicitudId: 's-$id',
      estado: estado,
      tipo: TipoLimpieza.general,
      zona: 'Petare',
      inicio: DateTime.now().add(const Duration(days: 3)),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      clienteNombre: 'María Alejandra',
      estadoSolicitud: estadoSolicitud,
      motivoCancelacion: motivo,
      canceladaPorMi: canceladaPorMi,
    );

Widget _appTrabajadora(
  List<Postulacion> postulaciones,
  _ServiciosFalsos servicios,
) =>
    ProviderScope(
      overrides: [
        postulacionRepositoryProvider
            .overrideWithValue(_PostulacionesFalsas(postulaciones)),
        servicioRepositoryProvider.overrideWithValue(servicios),
        sesionProvider.overrideWith(_SesionTrabajadora.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const MisServiciosScreen(),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _elegirMotivo(WidgetTester tester, String motivo) async {
  await tester.tap(find.byKey(const Key('motivo-cancelar-servicio')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(motivo).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  group('HU-28 · el cliente cancela', () {
    testWidgets('c3: solo el servicio Asignado ofrece cancelarse',
        (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        _appCliente(
          _Datos([
            _solicitud('s1', EstadoSolicitud.asignada),
            _solicitud('s2', EstadoSolicitud.completada),
          ]),
          _ServiciosFalsos(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cancelar-servicio-s1')), findsOneWidget);
      expect(find.byKey(const Key('cancelar-servicio-s2')), findsNothing);
    });

    testWidgets('c2: sin motivo no se cancela', (tester) async {
      _pantallaGrande(tester);
      final servicios = _ServiciosFalsos();
      await tester.pumpWidget(
        _appCliente(
          _Datos([_solicitud('s1', EstadoSolicitud.asignada)]),
          servicios,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelar-servicio-s1')));
      await tester.pumpAndSettle();
      expect(find.text('¿Cancelar este servicio?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmar-cancelacion')));
      await tester.pumpAndSettle();

      expect(find.text('Elige un motivo'), findsOneWidget);
      expect(find.text('¿Cancelar este servicio?'), findsOneWidget);
      expect(servicios.canceladas, isEmpty);
    });

    testWidgets('con "No" no cambia nada', (tester) async {
      _pantallaGrande(tester);
      final servicios = _ServiciosFalsos();
      await tester.pumpWidget(
        _appCliente(
          _Datos([_solicitud('s1', EstadoSolicitud.asignada)]),
          servicios,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelar-servicio-s1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelar-cancelacion')));
      await tester.pumpAndSettle();

      expect(servicios.canceladas, isEmpty);
      expect(find.byKey(const Key('cancelar-servicio-s1')), findsOneWidget);
    });

    testWidgets('c1: con motivo queda Cancelada y lo muestra', (tester) async {
      _pantallaGrande(tester);
      final datos = _Datos([_solicitud('s1', EstadoSolicitud.asignada)]);
      final servicios = _ServiciosFalsos(datos);
      await tester.pumpWidget(_appCliente(datos, servicios));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelar-servicio-s1')));
      await tester.pumpAndSettle();
      await _elegirMotivo(tester, 'Cambio de planes');
      await tester.tap(find.byKey(const Key('confirmar-cancelacion')));
      await tester.pumpAndSettle();

      expect(servicios.canceladas, {'s1': 'Cambio de planes'});
      expect(find.text('Motivo: Cambio de planes'), findsOneWidget);
      expect(find.byKey(const Key('cancelar-servicio-s1')), findsNothing);
    });

    testWidgets('c1: si la canceló la trabajadora, el cliente lo ve',
        (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        _appCliente(
          _Datos([
            _solicitud(
              's1',
              EstadoSolicitud.cancelada,
              motivo: 'Tengo un imprevisto',
              canceladaPor: 't1',
            ),
          ]),
          _ServiciosFalsos(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cancelado por Carmen Pérez · Motivo: Tengo un imprevisto'),
        findsOneWidget,
      );
    });
  });

  group('HU-28 · la trabajadora cancela', () {
    testWidgets('c1 y c3: solo el servicio Asignado ofrece cancelarse',
        (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        _appTrabajadora(
          [
            _postulacion(
              '1',
              EstadoPostulacion.aceptada,
              EstadoSolicitud.asignada,
            ),
            _postulacion(
              '2',
              EstadoPostulacion.aceptada,
              EstadoSolicitud.completada,
            ),
          ],
          _ServiciosFalsos(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cancelar-servicio-p-1')), findsOneWidget);
      expect(find.byKey(const Key('cancelar-servicio-p-2')), findsNothing);
    });

    testWidgets('c1: cancela con motivo', (tester) async {
      _pantallaGrande(tester);
      final servicios = _ServiciosFalsos();
      await tester.pumpWidget(
        _appTrabajadora(
          [
            _postulacion(
              '1',
              EstadoPostulacion.aceptada,
              EstadoSolicitud.asignada,
            ),
          ],
          servicios,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelar-servicio-p-1')));
      await tester.pumpAndSettle();
      await _elegirMotivo(tester, 'Tengo un imprevisto');
      await tester.tap(find.byKey(const Key('confirmar-cancelacion')));
      await tester.pumpAndSettle();

      expect(servicios.canceladas, {'s-1': 'Tengo un imprevisto'});
    });

    testWidgets('c1: ve el motivo cuando el cliente canceló', (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        _appTrabajadora(
          [
            _postulacion(
              '1',
              EstadoPostulacion.solicitudCancelada,
              EstadoSolicitud.cancelada,
              motivo: 'Cambio de planes',
            ),
          ],
          _ServiciosFalsos(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Motivo: Cambio de planes'), findsOneWidget);
      expect(find.text('El cliente canceló esta solicitud.'), findsOneWidget);
    });

    testWidgets('si la canceló ella, no la cuenta como "por el cliente"',
        (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(
        _appTrabajadora(
          [
            _postulacion(
              '1',
              EstadoPostulacion.solicitudCancelada,
              EstadoSolicitud.cancelada,
              motivo: 'Tengo un imprevisto',
              canceladaPorMi: true,
            ),
          ],
          _ServiciosFalsos(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancelaste este servicio.'), findsOneWidget);
      expect(find.text('El cliente canceló esta solicitud.'), findsNothing);
    });
  });
}
