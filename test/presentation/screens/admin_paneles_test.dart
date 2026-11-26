import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/cuenta_usuario.dart';
import 'package:limpiaya/domain/entities/metricas_plataforma.dart';
import 'package:limpiaya/domain/entities/resena_reportada.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/repositories/admin_repository.dart';
import 'package:limpiaya/domain/services/admin_service.dart';
import 'package:limpiaya/presentation/screens/admin/panel_cuentas_admin.dart';
import 'package:limpiaya/presentation/screens/admin/panel_metricas_admin.dart';
import 'package:limpiaya/presentation/screens/admin/panel_moderacion_admin.dart';

class _AdminRepoFalso implements AdminRepository {
  _AdminRepoFalso({
    this.cuentas = const [],
    this.reportes = const [],
  });

  final List<CuentaUsuario> cuentas;
  final List<ResenaReportada> reportes;

  final suspendidas = <String, String>{};
  final reactivadas = <String>[];
  final ocultadas = <String>[];
  final mantenidas = <String>[];

  @override
  Future<List<CuentaUsuario>> listarCuentas() async => cuentas;

  @override
  Future<void> suspenderCuenta(String usuarioId, String motivo) async {
    suspendidas[usuarioId] = motivo;
  }

  @override
  Future<void> reactivarCuenta(String usuarioId) async {
    reactivadas.add(usuarioId);
  }

  @override
  Future<List<ResenaReportada>> listarResenasReportadas() async => reportes;

  @override
  Future<void> ocultarResena(String reporteId, {String? nota}) async {
    ocultadas.add(reporteId);
  }

  @override
  Future<void> mantenerResena(String reporteId, {String? nota}) async {
    mantenidas.add(reporteId);
  }

  @override
  Future<void> reportarResena(String calificacionId, String motivo) async {}

  @override
  Future<MetricasPlataforma> metricas(DateTime mes) async => MetricasPlataforma(
        mes: mes,
        totalSolicitudes: 10,
        solicitudesConPostulacion: 8,
        pctConPostulacion: 80.0,
        solicitudesAsignadas: 2,
        solicitudesCompletadas: 6,
        solicitudesCanceladas: 1,
        pctCompletado: 60.0,
        clientesNuevos: 4,
        trabajadorasNuevas: 3,
        trabajadorasVerificadas: 9,
        volumenUsd: 240.0,
      );
}

Widget _envolver(_AdminRepoFalso repo, Widget hijo) => ProviderScope(
      overrides: [
        adminRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: hijo,
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-34 · exige motivo al suspender y permite suspender/reactivar',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _AdminRepoFalso(
      cuentas: [
        CuentaUsuario(
          id: 'u1',
          nombre: 'Luis Fernández',
          rol: RolUsuario.cliente,
          activo: true,
          suspendido: false,
          serviciosActivos: 2,
          creadoEn: DateTime(2026, 11, 1),
        ),
        CuentaUsuario(
          id: 'u2',
          nombre: 'Carmen López',
          rol: RolUsuario.trabajadora,
          activo: true,
          suspendido: true,
          motivoSuspension: 'Incumplimiento previo',
          serviciosActivos: 0,
          creadoEn: DateTime(2026, 11, 2),
        ),
      ],
    );

    await tester.pumpWidget(_envolver(repo, const PanelCuentasAdmin()));
    await tester.pumpAndSettle();

    expect(find.text('Luis Fernández'), findsOneWidget);
    expect(find.text('Carmen López'), findsOneWidget);

    // Intentar suspender sin motivo muestra error
    await tester.tap(find.text('Suspender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suspender cuenta'));
    await tester.pumpAndSettle();
    expect(find.text(AdminService.errorMotivoSuspension), findsOneWidget);

    // Escribir motivo y suspender
    await tester.enterText(
      find.byType(TextFormField).last,
      'Cancelaciones reiteradas',
    );
    await tester.tap(find.text('Suspender cuenta'));
    await tester.pumpAndSettle();
    expect(repo.suspendidas['u1'], 'Cancelaciones reiteradas');

    // Reactivar cuenta suspendida
    await tester.tap(find.text('Reactivar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reactivar').last);
    await tester.pumpAndSettle();
    expect(repo.reactivadas, ['u2']);
  });

  testWidgets('HU-35 · cola de moderación permite ocultar reseña reportada',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _AdminRepoFalso(
      reportes: [
        ResenaReportada(
          reporteId: 'rep-1',
          calificacionId: 'cal-1',
          estrellas: 1,
          comentario: 'Comentario ofensivo de prueba',
          autorNombre: 'Luis Fernández',
          destinatarioNombre: 'Carmen López',
          reportadoPorNombre: 'Carmen López',
          motivoReporte: 'Lenguaje inapropiado',
          estado: 'pendiente',
          creadoEn: DateTime(2026, 11, 20),
        ),
      ],
    );

    await tester.pumpWidget(_envolver(repo, const PanelModeracionAdmin()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Comentario ofensivo de prueba'), findsOneWidget);
    expect(find.textContaining('Lenguaje inapropiado'), findsOneWidget);

    await tester.tap(find.text('Ocultar reseña'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ocultar reseña').last);
    await tester.pumpAndSettle();

    expect(repo.ocultadas, ['rep-1']);
  });

  testWidgets('HU-36 · métricas muestran totales del mes, % postulación y % completado',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _AdminRepoFalso();

    await tester.pumpWidget(_envolver(repo, const PanelMetricasAdmin()));
    await tester.pumpAndSettle();

    expect(find.text('Solicitudes del mes'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('% con postulación'), findsOneWidget);
    expect(find.text('80.0 %'), findsOneWidget);
    expect(find.text('% completado'), findsOneWidget);
    expect(find.text('60.0 %'), findsOneWidget);
    expect(find.text('\$240.00'), findsOneWidget);
  });
}
