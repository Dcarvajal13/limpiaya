import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/perfil_publico.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/trabajadora_publica_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/perfil/perfil_publico_screen.dart';

class _PerfilFalso implements TrabajadoraPublicaRepository {
  _PerfilFalso(this.datos);

  final PerfilPublico? datos;

  @override
  Future<PerfilPublico?> perfil(String trabajadoraId) async => datos;
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'cliente-1',
        rol: RolUsuario.cliente,
        nombre: 'María Alejandra',
        perfilCompleto: true,
      );
}

PerfilPublico _perfil({
  List<ResenaPublica> resenas = const [],
  double? promedio = 4.8,
  int totalResenas = 12,
}) =>
    PerfilPublico(
      id: 't-1',
      nombre: 'Carmen Pérez',
      experienciaAnios: 6,
      tarifaReferencia: 8,
      descripcion: 'Limpio con productos ecoamigables.',
      verificada: true,
      zonas: const ['Los Palos Grandes', 'Altamira'],
      servicios: const [TipoLimpieza.general, TipoLimpieza.profunda],
      promedio: promedio,
      totalResenas: totalResenas,
      serviciosCompletados: 8,
      resenas: resenas,
    );

Widget _app(TrabajadoraPublicaRepository repo) {
  return ProviderScope(
    overrides: [
      trabajadoraPublicaRepositoryProvider.overrideWithValue(repo),
      sesionProvider.overrideWith(_SesionFalsa.new),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const PerfilPublicoScreen(trabajadoraId: 't-1'),
    ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-06 c1: muestra datos, zonas, servicios y reseñas',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_PerfilFalso(_perfil(resenas: const [
        ResenaPublica(
          estrellas: 5,
          autorNombre: 'María Alejandra',
          comentario: 'Llegó puntual y dejó todo impecable.',
        ),
      ]))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carmen Pérez'), findsOneWidget);
    expect(find.text('Identidad verificada'), findsOneWidget);
    expect(find.textContaining('4,8'), findsOneWidget);
    expect(find.textContaining('12 reseñas'), findsOneWidget);
    expect(find.textContaining('6 años de experiencia'), findsOneWidget);
    expect(find.textContaining('8 servicios completados'), findsOneWidget);
    expect(find.text('Los Palos Grandes'), findsOneWidget);
    expect(find.text('Limpieza general'), findsOneWidget);
    expect(find.textContaining('Llegó puntual'), findsOneWidget);
    expect(find.text('María Alejandra'), findsOneWidget);
  });

  testWidgets('HU-06 c2: sin reseñas muestra el mensaje', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_PerfilFalso(_perfil(promedio: null, totalResenas: 0))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tiene reseñas'), findsOneWidget);
  });

  testWidgets('HU-06 c3: nunca muestra teléfono ni correo', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_PerfilFalso(_perfil())));
    await tester.pumpAndSettle();

    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('+58'), findsNothing);
    expect(find.textContaining('0414'), findsNothing);
  });

  testWidgets('si el perfil no existe lo dice', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_PerfilFalso(null)));
    await tester.pumpAndSettle();

    expect(find.text('No encontramos esta trabajadora'), findsOneWidget);
  });

  testWidgets('renderiza sin desbordamiento en móvil (390x844)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(_PerfilFalso(_perfil(resenas: const [
        ResenaPublica(
          estrellas: 4,
          autorNombre: 'Luis',
          comentario: 'Muy bien, aunque llegó un poco tarde.',
        ),
      ]))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
