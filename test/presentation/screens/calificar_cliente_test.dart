import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/calificacion.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/motivo_calificacion_baja.dart';
import 'package:limpiaya/domain/entities/postulacion.dart';
import 'package:limpiaya/domain/entities/postulante.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/calificacion_repository.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/services/calificacion_service.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/mis_servicios_screen.dart';

/// Lo que comparten los repositorios falsos, como lo haría la base real.
class _Datos {
  _Datos({this.estadoSolicitud = EstadoSolicitud.completada, int? estrellas})
      : calificacion = estrellas == null
            ? null
            : Calificacion(
                solicitudId: 's-1',
                estrellas: estrellas,
                comentario: 'Pagó a tiempo',
                fecha: DateTime(2026, 11, 9),
              );

  final EstadoSolicitud estadoSolicitud;
  Calificacion? calificacion;
  final enviadas = <({
    String destinatario,
    int estrellas,
    MotivoCalificacionBaja? motivo,
  })>[];
}

class _PostulacionesFalsas implements PostulacionRepository {
  _PostulacionesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<List<Postulacion>> misPostulaciones() async => [
        Postulacion(
          id: 'p-1',
          solicitudId: 's-1',
          estado: EstadoPostulacion.aceptada,
          tipo: TipoLimpieza.general,
          zona: 'Petare',
          inicio: DateTime(2026, 11, 9, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
          clienteNombre: 'María Alejandra',
          clienteId: 'c1',
          estadoSolicitud: datos.estadoSolicitud,
          miCalificacion: datos.calificacion?.estrellas,
        ),
      ];

  @override
  Future<void> retirar(String postulacionId) async {}

  @override
  Future<List<Postulante>> postulantesDe(String solicitudId) async => const [];

  @override
  Future<void> postular({required String solicitudId, String? mensaje}) async {}
}

class _CalificacionesFalsas implements CalificacionRepository {
  _CalificacionesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<Calificacion?> miCalificacion(String solicitudId) async =>
      datos.calificacion;

  @override
  Future<void> calificar({
    required String solicitudId,
    required String destinatarioId,
    required int estrellas,
    String? comentario,
    MotivoCalificacionBaja? motivo,
  }) async {
    datos.enviadas.add(
      (destinatario: destinatarioId, estrellas: estrellas, motivo: motivo),
    );
    datos.calificacion = Calificacion(
      solicitudId: solicitudId,
      estrellas: estrellas,
      comentario: comentario,
    );
  }
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 't1',
        rol: RolUsuario.trabajadora,
        nombre: 'Carmen Pérez',
        perfilCompleto: true,
      );
}

Widget _app(_Datos datos) => ProviderScope(
      overrides: [
        postulacionRepositoryProvider
            .overrideWithValue(_PostulacionesFalsas(datos)),
        calificacionRepositoryProvider
            .overrideWithValue(_CalificacionesFalsas(datos)),
        sesionProvider.overrideWith(_SesionFalsa.new),
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

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('calificar-cliente-p-1')));
  await tester.pumpAndSettle();
  expect(find.text('Califica a María Alejandra'), findsOneWidget);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('solo un servicio Completado ofrece calificar al cliente',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_Datos(estadoSolicitud: EstadoSolicitud.asignada)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calificar-cliente-p-1')), findsNothing);
  });

  testWidgets('HU-30 c1: con 5 estrellas se guarda sin pedir motivo',
      (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos();
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();
    expect(
      find.text('Servicio completado. Califica al cliente.'),
      findsOneWidget,
    );

    await _abrir(tester);
    await tester.tap(find.byTooltip('5 de 5'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('motivo-calificacion')), findsNothing);
    await tester.tap(find.byKey(const Key('enviar-calificacion')));
    await tester.pumpAndSettle();

    expect(datos.enviadas, hasLength(1));
    expect(datos.enviadas.single.destinatario, 'c1');
    expect(datos.enviadas.single.estrellas, 5);
    expect(datos.enviadas.single.motivo, isNull);
    expect(find.text(CalificacionService.mensajeEnviada), findsOneWidget);
  });

  testWidgets('HU-30 c2: con 2 estrellas exige el motivo', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos();
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await _abrir(tester);
    await tester.tap(find.byTooltip('2 de 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enviar-calificacion')));
    await tester.pumpAndSettle();

    expect(find.text(CalificacionService.mensajeEligeMotivo), findsOneWidget);
    expect(datos.enviadas, isEmpty);

    await tester.tap(find.byKey(const Key('motivo-calificacion')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pago incompleto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enviar-calificacion')));
    await tester.pumpAndSettle();

    expect(datos.enviadas, hasLength(1));
    expect(datos.enviadas.single.estrellas, 2);
    expect(
      datos.enviadas.single.motivo,
      MotivoCalificacionBaja.pagoIncompleto,
    );
  });

  testWidgets('HU-30 c3: si ya calificó, solo puede verla', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos(estrellas: 4);
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    expect(
      find.text('Servicio completado. Calificaste al cliente con ★ 4.'),
      findsOneWidget,
    );
    expect(find.text('Ver mi calificación'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calificar-cliente-p-1')));
    await tester.pumpAndSettle();

    expect(find.text('Tu calificación a María Alejandra'), findsOneWidget);
    expect(find.byKey(const Key('enviar-calificacion')), findsNothing);
    expect(datos.enviadas, isEmpty);
  });
}
