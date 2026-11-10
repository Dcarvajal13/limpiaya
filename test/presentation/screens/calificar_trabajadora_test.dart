import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/calificacion.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/motivo_calificacion_baja.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/calificacion_repository.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/domain/services/calificacion_service.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/mis_solicitudes_screen.dart';

/// Lo que comparten los repositorios falsos, como lo haría la base real.
class _Datos {
  _Datos({int? estrellas, String? comentario})
      : calificacion = estrellas == null
            ? null
            : Calificacion(
                solicitudId: 's1',
                estrellas: estrellas,
                comentario: comentario,
                fecha: DateTime(2026, 11, 9),
              );

  Calificacion? calificacion;
  final enviadas = <({String destinatario, int estrellas, String? comentario})>[];
}

class _SolicitudesFalsas implements SolicitudRepository {
  _SolicitudesFalsas(this.datos);

  final _Datos datos;

  @override
  Future<List<Solicitud>> misSolicitudes() async => [
        Solicitud(
          id: 's1',
          clienteId: 'c1',
          trabajadoraId: 't1',
          trabajadoraNombre: 'Carmen Pérez',
          estado: EstadoSolicitud.completada,
          tipo: TipoLimpieza.general,
          zonaId: 1,
          zona: 'Petare',
          inicio: DateTime(2026, 11, 9, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
          metodoPago: MetodoPago.pagoMovil,
          numPostulantes: 1,
          miCalificacion: datos.calificacion?.estrellas,
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
      (destinatario: destinatarioId, estrellas: estrellas, comentario: comentario),
    );
    datos.calificacion = Calificacion(
      solicitudId: solicitudId,
      estrellas: estrellas,
      comentario: comentario,
    );
  }
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

Widget _app(_Datos datos) => ProviderScope(
      overrides: [
        solicitudRepositoryProvider.overrideWithValue(_SolicitudesFalsas(datos)),
        calificacionRepositoryProvider
            .overrideWithValue(_CalificacionesFalsas(datos)),
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

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-29 c2: sin estrellas no se envía', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos();
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calificar-s1')));
    await tester.pumpAndSettle();
    expect(find.text('Califica a Carmen Pérez'), findsOneWidget);

    await tester.tap(find.byKey(const Key('enviar-calificacion')));
    await tester.pumpAndSettle();

    expect(find.text(CalificacionService.mensajeEligeEstrellas), findsOneWidget);
    expect(find.text('Califica a Carmen Pérez'), findsOneWidget);
    expect(datos.enviadas, isEmpty);
  });

  testWidgets('HU-29 c1: con estrellas y comentario se guarda', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos();
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calificar-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('4 de 5'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('comentario-calificacion')),
      '  Muy puntual  ',
    );
    await tester.tap(find.byKey(const Key('enviar-calificacion')));
    await tester.pumpAndSettle();

    expect(datos.enviadas, hasLength(1));
    expect(datos.enviadas.single.destinatario, 't1');
    expect(datos.enviadas.single.estrellas, 4);
    expect(datos.enviadas.single.comentario, 'Muy puntual');
    expect(find.text(CalificacionService.mensajeEnviada), findsOneWidget);
    // c3: la tarjeta recuerda la calificación y ya no ofrece calificar.
    expect(find.text('La calificaste con ★ 4'), findsOneWidget);
    expect(find.text('Ver mi calificación'), findsOneWidget);
  });

  testWidgets('HU-29 c3: si ya calificó, solo puede verla', (tester) async {
    _pantallaGrande(tester);
    final datos = _Datos(estrellas: 5, comentario: 'Excelente trabajo');
    await tester.pumpWidget(_app(datos));
    await tester.pumpAndSettle();

    expect(find.text('Calificar'), findsNothing);
    await tester.tap(find.text('Ver mi calificación'));
    await tester.pumpAndSettle();

    expect(find.text('Tu calificación a Carmen Pérez'), findsOneWidget);
    expect(find.text('“Excelente trabajo”'), findsOneWidget);
    expect(find.byKey(const Key('enviar-calificacion')), findsNothing);

    await tester.tap(find.byKey(const Key('cerrar-mi-calificacion')));
    await tester.pumpAndSettle();
    expect(datos.enviadas, isEmpty);
  });
}
