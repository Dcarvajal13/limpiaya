import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/reputacion_repository.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/solicitudes_disponibles_screen.dart';

class _RepositorioFalso implements SolicitudRepository {
  _RepositorioFalso({this.zonas = const [], this.solicitudes = const []});

  /// Se puede cambiar en la prueba, como si la trabajadora editara su perfil.
  List<Zona> zonas;
  final List<SolicitudDisponible> solicitudes;

  @override
  Future<List<Zona>> misZonas() async => zonas;

  @override
  Future<List<SolicitudDisponible>> disponibles() async =>
      zonas.isEmpty ? const [] : solicitudes;

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async => 'id-de-prueba';

  @override
  Future<DireccionCliente?> miDireccion() async => null;
}

class _ReputacionFalsa implements ReputacionRepository {
  const _ReputacionFalsa(this.promedio);

  final double? promedio;

  @override
  Future<double?> miPromedio() async => promedio;
}

class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this.verificacion);

  final String? verificacion;

  @override
  Future<Sesion?> build() async => Sesion(
    id: 'u1',
    rol: RolUsuario.trabajadora,
    nombre: 'Carmen Pérez',
    perfilCompleto: true,
    verificacion: verificacion,
  );
}

SolicitudDisponible _solicitud(
  String id,
  TipoLimpieza tipo, {
  bool tieneMascotas = false,
}) {
  return SolicitudDisponible(
    id: id,
    tipo: tipo,
    zonaId: 1,
    zona: 'Chacao (casco)',
    inicio: DateTime.now().add(const Duration(days: 2)),
    horasEstimadas: 4,
    pagoOfrecido: 28,
    metodoPago: MetodoPago.transferencia,
    numPostulantes: 3,
    habitaciones: 3,
    banos: 2,
    tieneMascotas: tieneMascotas,
  );
}

Widget _app(
  _RepositorioFalso repositorio, {
  String? verificacion = 'aprobada',
  double? promedio = 4.9,
}) {
  return ProviderScope(
    overrides: [
      solicitudRepositoryProvider.overrideWithValue(repositorio),
      reputacionRepositoryProvider.overrideWithValue(_ReputacionFalsa(promedio)),
      sesionProvider.overrideWith(() => _SesionFalsa(verificacion)),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const SolicitudesDisponiblesScreen(),
    ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-11 c3: sin solicitudes en sus zonas muestra el mensaje', (
    tester,
  ) async {
    _pantallaGrande(tester);

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
    _pantallaGrande(tester);

    await tester.pumpWidget(_app(_RepositorioFalso()));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes zonas de trabajo'), findsOneWidget);
  });

  testWidgets('banner: insignia de identidad verificada con el promedio', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(
      _app(
        _RepositorioFalso(
          zonas: const [Zona(id: 1, nombre: 'Chacao (casco)')],
          solicitudes: [_solicitud('a', TipoLimpieza.general)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Identidad verificada'), findsOneWidget);
    expect(find.text('4,9'), findsOneWidget);
    expect(
      find.text(
        'Hay 1 trabajo disponible en tus zonas. '
        'Elige los que se ajusten mejor a tu horario.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('banner: sin verificar y sin reseñas no muestra estrellas', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(
      _app(
        _RepositorioFalso(zonas: const [Zona(id: 1, nombre: 'Altamira')]),
        verificacion: 'en_revision',
        promedio: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificación en revisión'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('HU-11 c1/c2: muestra tarjetas y filtra con "Filtrar"', (
    tester,
  ) async {
    _pantallaGrande(tester);

    await tester.pumpWidget(
      _app(
        _RepositorioFalso(
          zonas: const [Zona(id: 1, nombre: 'Chacao (casco)')],
          solicitudes: [
            _solicitud('a', TipoLimpieza.general),
            _solicitud('b', TipoLimpieza.profunda, tieneMascotas: true),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'Recibes $28'), findsNWidgets(2));
    expect(find.text('3 postulantes'), findsNWidgets(2));
    expect(find.text('3 hab.'), findsNWidgets(2));
    expect(find.text('2 baños'), findsNWidgets(2));
    expect(find.text('Chacao (casco), Caracas'), findsNWidgets(2));

    // Elegir "Profunda" no filtra hasta tocar "Filtrar".
    await tester.tap(find.byType(DropdownButtonFormField<TipoLimpieza?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profunda').last);
    await tester.pumpAndSettle();
    expect(find.text(r'Recibes $28'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('boton-filtrar')));
    await tester.pumpAndSettle();
    expect(find.text(r'Recibes $28'), findsOneWidget);

    // "Profunda" + "Sin mascotas": la única profunda tiene mascotas.
    await tester.tap(find.byKey(const Key('filtro-sin-mascotas')));
    await tester.tap(find.byKey(const Key('boton-filtrar')));
    await tester.pumpAndSettle();
    expect(
      find.text('Ninguna solicitud coincide con tus filtros'),
      findsOneWidget,
    );

    await tester.tap(find.text('Quitar filtros'));
    await tester.pumpAndSettle();
    expect(find.text(r'Recibes $28'), findsNWidgets(2));
  });

  testWidgets(
    'al guardar el perfil con otras zonas, la lista usa las zonas nuevas',
    (tester) async {
      _pantallaGrande(tester);
      final repositorio = _RepositorioFalso(
        zonas: const [Zona(id: 1, nombre: 'Altamira')],
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();
      expect(find.text('Por ahora no hay trabajos en Altamira.'), findsOneWidget);

      // HU-04 guarda las zonas nuevas y recarga la sesión.
      repositorio.zonas = const [
        Zona(id: 2, nombre: 'Chacao (casco)'),
        Zona(id: 3, nombre: 'El Cafetal'),
      ];
      ProviderScope.containerOf(
        tester.element(find.byType(SolicitudesDisponiblesScreen)),
      ).invalidate(sesionProvider);
      await tester.pumpAndSettle();

      expect(
        find.text('Por ahora no hay trabajos en Chacao (casco) y El Cafetal.'),
        findsOneWidget,
      );
      expect(find.text('Altamira'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'El Cafetal'), findsOneWidget);
    },
  );
}
