import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/servicio_agendado.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/servicio_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/mis_solicitudes_screen.dart';

/// Lista de solicitudes que cambia cuando el servicio falso las completa.
class _Datos {
  _Datos(this.solicitudes);

  List<Solicitud> solicitudes;
  final completadas = <String>[];
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

class _ServiciosFalsos implements ServicioRepository {
  _ServiciosFalsos(this.datos);

  final _Datos datos;

  @override
  Future<void> elegir(String postulacionId) async {}

  @override
  Future<void> completar(String solicitudId) async {
    datos.completadas.add(solicitudId);
    datos.solicitudes = [
      for (final s in datos.solicitudes)
        s.id == solicitudId
            ? _solicitud(s.id, EstadoSolicitud.completada, s.inicio)
            : s,
    ];
  }

  @override
  Future<List<ServicioAgendado>> misServicios() async => const [];

  @override
  Future<ServicioAgendado?> servicioAgendado(String id) async => null;
}

class _ReputacionFalsa implements ReputacionRepository {
  @override
  Future<double?> miPromedio() async => null;
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

Solicitud _solicitud(String id, EstadoSolicitud estado, DateTime inicio) =>
    Solicitud(
      id: id,
      clienteId: 'c1',
      trabajadoraId: 't1',
      trabajadoraNombre: 'Carmen Pérez',
      estado: estado,
      tipo: TipoLimpieza.general,
      zonaId: 1,
      zona: 'Petare',
      inicio: inicio,
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 1,
    );

/// Un servicio que empezó hace 3 horas y otro que empieza en 3 días.
final _yaEmpezo = DateTime.now().subtract(const Duration(hours: 3));
final _futuro = DateTime.now().add(const Duration(days: 3));

Widget _app(_Datos datos) => ProviderScope(
      overrides: [
        solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas(datos)),
        servicioRepositoryProvider.overrideWithValue(_ServiciosFalsos(datos)),
        reputacionRepositoryProvider.overrideWithValue(_ReputacionFalsa()),
        sesionProvider.overrideWith(_SesionFalsa.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const MisSolicitudesScreen(),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _confirmarCompletar(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('completar-$id')));
  await tester.pumpAndSettle();
  expect(find.text('¿La limpieza ya se hizo?'), findsOneWidget);
  await tester.tap(find.byKey(const Key('confirmar-completar')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-17 c2: solo el servicio que ya empezó ofrece completarse',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_Datos([
        _solicitud('s1', EstadoSolicitud.asignada, _yaEmpezo),
        _solicitud('s2', EstadoSolicitud.asignada, _futuro),
      ])),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('completar-s1')), findsOneWidget);
    expect(find.byKey(const Key('completar-s2')), findsNothing);
  });

  testWidgets('HU-17: con "Todavía no" no cambia nada', (tester) async {
    _pantallaGrande(tester);
    final datos =
        _Datos([_solicitud('s1', EstadoSolicitud.asignada, _yaEmpezo)]);
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('completar-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancelar-completar')));
    await tester.pumpAndSettle();

    expect(datos.completadas, isEmpty);
    expect(find.byKey(const Key('completar-s1')), findsOneWidget);
  });

  testWidgets('HU-17 c1 y c3: al confirmar pasa a Completado e invita a '
      'calificar', (tester) async {
    _pantallaGrande(tester);
    final datos =
        _Datos([_solicitud('s1', EstadoSolicitud.asignada, _yaEmpezo)]);
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await _confirmarCompletar(tester, 's1');

    expect(datos.completadas, ['s1']);
    // c3: invitación a calificar.
    expect(find.text('¡Servicio completado!'), findsOneWidget);
    expect(find.textContaining('calificar a Carmen Pérez'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calificar-despues')));
    await tester.pumpAndSettle();

    // c1: la tarjeta ya está Completada y ofrece calificar.
    expect(find.byKey(const Key('completar-s1')), findsNothing);
    expect(find.text('Calificar'), findsOneWidget);
  });
}
