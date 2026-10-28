import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/postulacion.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/postulacion_repository.dart';
import 'package:limpiaya/domain/services/postulacion_service.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/mis_servicios_screen.dart';

/// Repositorio en memoria: retirar() quita la postulación, como en la base.
class _RepositorioFalso implements PostulacionRepository {
  _RepositorioFalso(this.postulaciones, {this.error});

  final List<Postulacion> postulaciones;

  /// Si viene, `retirar()` falla con este mensaje (HU-26 c2).
  final String? error;

  final retiradas = <String>[];

  @override
  Future<List<Postulacion>> misPostulaciones() async => postulaciones;

  @override
  Future<void> postular({required String solicitudId, String? mensaje}) async {}

  @override
  Future<void> retirar(String postulacionId) async {
    retiradas.add(postulacionId);
    if (error != null) throw AppException(error!);
    postulaciones.removeWhere((p) => p.id == postulacionId);
  }
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'trabajadora-1',
        rol: RolUsuario.trabajadora,
        nombre: 'Carmen Pérez',
        perfilCompleto: true,
        verificacion: 'aprobada',
      );
}

Postulacion _postulacion(String id, EstadoPostulacion estado) => Postulacion(
      id: 'p-$id',
      solicitudId: 's-$id',
      estado: estado,
      tipo: TipoLimpieza.general,
      zona: 'Chacao (casco)',
      inicio: DateTime(2026, 10, 30, 9),
      horasEstimadas: 4,
      pagoOfrecido: 40,
      clienteNombre: 'María Alejandra',
    );

Widget _app(PostulacionRepository repo) {
  return ProviderScope(
    overrides: [
      postulacionRepositoryProvider.overrideWithValue(repo),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: MaterialApp(theme: AppTheme.claro, home: const MisServiciosScreen()),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-26 c1: retira una postulación pendiente y desaparece', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso([
      _postulacion('1', EstadoPostulacion.pendiente),
    ]);

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Pendiente'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retirar-p-1')));
    await tester.pumpAndSettle();
    // Pide confirmación antes de retirar.
    expect(find.text('Retirar postulación'), findsWidgets);
    expect(repo.retiradas, isEmpty);

    await tester.tap(find.byKey(const Key('confirmar-retirar')));
    await tester.pumpAndSettle();

    expect(repo.retiradas, ['p-1']);
    expect(find.text('Pendiente'), findsNothing);
    expect(
      find.text('Aún no te has postulado a ningún trabajo'),
      findsOneWidget,
    );
    expect(find.text(PostulacionService.mensajeRetirada), findsOneWidget);
  });

  testWidgets('HU-26 c1: si cancela no se retira nada', (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso([
      _postulacion('1', EstadoPostulacion.pendiente),
    ]);

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('retirar-p-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancelar-retirar')));
    await tester.pumpAndSettle();

    expect(repo.retiradas, isEmpty);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('HU-26 c2: una postulación aceptada no ofrece retirarse', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso([
      _postulacion('2', EstadoPostulacion.aceptada),
    ]);

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Retirar postulación'), findsNothing);
    expect(find.text('Ver servicio'), findsOneWidget);
  });

  testWidgets('HU-26 c2: si la base la rechaza, avisa y la tarjeta sigue', (
    tester,
  ) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(
      [_postulacion('1', EstadoPostulacion.pendiente)],
      error: PostulacionService.mensajeSoloPendiente,
    );

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('retirar-p-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-retirar')));
    await tester.pumpAndSettle();

    expect(
      find.text(PostulacionService.mensajeSoloPendiente),
      findsOneWidget,
    );
    expect(find.text('Pendiente'), findsOneWidget);
  });
}
