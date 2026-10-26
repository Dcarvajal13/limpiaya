import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/solicitudes_disponibles_screen.dart';import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';

class _RepositorioFalso implements SolicitudRepository {
  _RepositorioFalso({this.zonas = const [], this.solicitudes = const []});

  final List<Zona> zonas;
  final List<SolicitudDisponible> solicitudes;

  @override
  Future<List<Zona>> misZonas() async => zonas;

  @override
  Future<List<SolicitudDisponible>> disponibles() async => solicitudes;

    @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id-de-prueba';

  @override
  Future<DireccionCliente?> miDireccion() async => null;
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
    id: 'u1',
    rol: RolUsuario.trabajadora,
    nombre: 'Carmen Pérez',
    perfilCompleto: true,
  );
}

SolicitudDisponible _solicitud(
  String id,
  TipoLimpieza tipo, {
  int zonaId = 1,
  String zona = 'Chacao (casco)',
}) {
  return SolicitudDisponible(
    id: id,
    tipo: tipo,
    zonaId: zonaId,
    zona: zona,
    inicio: DateTime.now().add(const Duration(days: 2)),
    horasEstimadas: 4,
    pagoOfrecido: 28,
    metodoPago: MetodoPago.transferencia,
    numPostulantes: 3,
  );
}

Widget _app(_RepositorioFalso repositorio) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repositorio),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const SolicitudesDisponiblesScreen(),
    ),
  );
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-11 c3: sin solicitudes en sus zonas muestra el mensaje', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(_RepositorioFalso(zonas: const [Zona(id: 1, nombre: 'Altamira')])),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(', Carmen'), findsOneWidget);
    expect(
      find.text('No hay solicitudes en tus zonas por ahora'),
      findsOneWidget,
    );
  });

  testWidgets('cuenta nueva sin zonas: invita a elegirlas', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_RepositorioFalso()));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes zonas de trabajo'), findsOneWidget);
  });

  testWidgets('HU-11 c1/c2: muestra tarjetas y filtra por tipo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        _RepositorioFalso(
          zonas: const [Zona(id: 1, nombre: 'Chacao (casco)')],
          solicitudes: [
            _solicitud('a', TipoLimpieza.general),
            _solicitud('b', TipoLimpieza.profunda),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Las dos tarjetas (además de los chips "General"/"Profunda").
    expect(find.text(r'$28'), findsNWidgets(2));
    expect(find.text('Transferencia · 3 postulantes'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Profunda'));
    await tester.pumpAndSettle();
    expect(find.text(r'$28'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Planchado'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ninguna solicitud coincide con tus filtros'),
      findsOneWidget,
    );

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.text(r'$28'), findsNWidgets(2));
  });
}
