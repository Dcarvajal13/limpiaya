import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/calificacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/servicio_agendado.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/motivo_calificacion_baja.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/calificacion_repository.dart';
import 'package:limpiaya/domain/repositories/servicio_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/servicio_agendado_screen.dart';

class _ServiciosFalsos implements ServicioRepository {
  _ServiciosFalsos(this.servicio);

  ServicioAgendado? servicio;
  final completados = <String>[];

  @override
  Future<void> elegir(String postulacionId) async {}

  @override
  Future<void> cancelar(String solicitudId, {required String motivo}) async {}

  @override
  Future<void> completar(String solicitudId) async {
    completados.add(solicitudId);
    final actual = servicio;
    if (actual != null) {
      servicio = ServicioAgendado(
        id: actual.id,
        estado: EstadoSolicitud.completada,
        tipo: actual.tipo,
        zona: actual.zona,
        inicio: actual.inicio,
        horasEstimadas: actual.horasEstimadas,
        pagoOfrecido: actual.pagoOfrecido,
        metodoPago: actual.metodoPago,
        soyCliente: actual.soyCliente,
        direccion: actual.direccion,
        puntoReferencia: actual.puntoReferencia,
        contraparteNombre: actual.contraparteNombre,
        contrapartePromedio: actual.contrapartePromedio,
        completadaEn: DateTime.now(),
      );
    }
  }

  @override
  Future<List<ServicioAgendado>> misServicios() async => [?servicio];

  @override
  Future<ServicioAgendado?> servicioAgendado(String id) async => servicio;
}

class _CalificacionesFalsas implements CalificacionRepository {
  Calificacion? existente;
  final enviadas = <({String destinatario, int estrellas})>[];

  @override
  Future<Calificacion?> miCalificacion(String solicitudId) async => existente;

  @override
  Future<void> calificar({
    required String solicitudId,
    required String destinatarioId,
    required int estrellas,
    String? comentario,
    MotivoCalificacionBaja? motivo,
  }) async {
    enviadas.add((destinatario: destinatarioId, estrellas: estrellas));
  }
}

class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this.rol);

  final RolUsuario rol;

  @override
  Future<Sesion?> build() async => Sesion(
        id: rol == RolUsuario.cliente ? 'c1' : 't1',
        rol: rol,
        nombre: rol == RolUsuario.cliente ? 'María Alejandra' : 'Carmen Pérez',
        perfilCompleto: true,
      );
}

ServicioAgendado _servicio({
  EstadoSolicitud estado = EstadoSolicitud.asignada,
  bool soyCliente = true,
  bool yaCalifique = false,
  DateTime? inicio,
}) =>
    ServicioAgendado(
      id: 's1',
      estado: estado,
      tipo: TipoLimpieza.profunda,
      zona: 'Los Palos Grandes',
      inicio: inicio ?? DateTime.now().subtract(const Duration(hours: 1)),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      soyCliente: soyCliente,
      direccion: 'Av. Principal, casa 4',
      puntoReferencia: 'frente a la panadería',
      notas: 'Hay un perro pequeño.',
      contraparteId: soyCliente ? 't1' : 'c1',
      contraparteNombre: soyCliente ? 'Carmen Pérez' : 'María Alejandra',
      contrapartePromedio: soyCliente ? 4.8 : null,
      yaCalifique: yaCalifique,
      completadaEn:
          estado == EstadoSolicitud.completada ? DateTime.now() : null,
    );

Widget _app(
  ServicioRepository repo,
  RolUsuario rol, {
  CalificacionRepository? calificaciones,
}) =>
    ProviderScope(
      overrides: [
        servicioRepositoryProvider.overrideWithValue(repo),
        sesionProvider.overrideWith(() => _SesionFalsa(rol)),
        if (calificaciones != null)
          calificacionRepositoryProvider.overrideWithValue(calificaciones),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const ServicioAgendadoScreen(solicitudId: 's1'),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-16 c2: el cliente ve todos los datos y la dirección',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _ServiciosFalsos(_servicio());
    await tester.pumpWidget(_app(repo, RolUsuario.cliente));
    await tester.pumpAndSettle();

    expect(find.text('Servicio agendado'), findsOneWidget);
    expect(find.text('Asignada'), findsOneWidget);
    expect(find.text('Limpieza profunda'), findsOneWidget);
    expect(find.text('Av. Principal, casa 4'), findsOneWidget);
    expect(find.textContaining('frente a la panadería'), findsOneWidget);
    expect(find.text('Los Palos Grandes · 4 horas'), findsOneWidget);
    expect(find.text(r'$30'), findsOneWidget);
    expect(find.text('Pago Móvil'), findsOneWidget);
    expect(find.text('Carmen Pérez'), findsOneWidget);
    expect(find.textContaining('★ 4,8'), findsOneWidget);
    expect(find.text('Hay un perro pequeño.'), findsOneWidget);
    expect(find.byKey(const Key('chat-servicio')), findsOneWidget);
  });

  testWidgets('HU-16 c2: la trabajadora ve al cliente, sin botón de completar',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _ServiciosFalsos(_servicio(soyCliente: false));
    await tester.pumpWidget(_app(repo, RolUsuario.trabajadora));
    await tester.pumpAndSettle();

    expect(find.text('María Alejandra'), findsOneWidget);
    expect(find.text('Recibes'), findsOneWidget);
    expect(find.byKey(const Key('completar-servicio')), findsNothing);
    expect(find.byKey(const Key('chat-servicio')), findsOneWidget);
  });

  testWidgets('HU-16 c4: completado sin calificar ofrece Calificar',
      (tester) async {
    _pantallaGrande(tester);
    final repo =
        _ServiciosFalsos(_servicio(estado: EstadoSolicitud.completada));
    await tester.pumpWidget(_app(repo, RolUsuario.cliente));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calificar-servicio')), findsOneWidget);
    expect(find.byKey(const Key('completar-servicio')), findsNothing);
  });

  testWidgets('HU-16 c4: Calificar abre el diálogo de HU-29 con la otra parte',
      (tester) async {
    _pantallaGrande(tester);
    final repo =
        _ServiciosFalsos(_servicio(estado: EstadoSolicitud.completada));
    final calificaciones = _CalificacionesFalsas();
    await tester.pumpWidget(
      _app(repo, RolUsuario.cliente, calificaciones: calificaciones),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calificar-servicio')));
    await tester.pumpAndSettle();

    expect(find.text('Califica a Carmen Pérez'), findsOneWidget);
  });

  testWidgets('HU-17: el cliente marca completado desde el detalle',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _ServiciosFalsos(_servicio());
    await tester.pumpWidget(_app(repo, RolUsuario.cliente));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('completar-servicio')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-completar')));
    await tester.pumpAndSettle();

    expect(repo.completados, ['s1']);
    expect(find.text('Completada'), findsOneWidget);
    expect(find.byKey(const Key('calificar-servicio')), findsOneWidget);
  });
}
