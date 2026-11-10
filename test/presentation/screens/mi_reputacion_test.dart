import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/mi_reputacion.dart';
import 'package:limpiaya/domain/entities/perfil_publico.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/repositories/mi_reputacion_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/mi_reputacion_screen.dart';

/// Guarda las respuestas en memoria, como lo haría la base: una por reseña
/// (responder de nuevo la reemplaza).
class _ReputacionFalsa implements MiReputacionRepository {
  _ReputacionFalsa({
    Map<String, String> respuestas = const {},
    this.destacada = false,
    this.servicios = 3,
    this.promedio = 4.7,
    this.cancelaciones = 0,
  }) : respuestas = {...respuestas};

  final Map<String, String> respuestas;
  final bool destacada;
  final int servicios;
  final double? promedio;
  final int cancelaciones;
  int llamadas = 0;

  @override
  Future<MiReputacion> miReputacion() async => MiReputacion(
        promedio: promedio,
        totalResenas: 1,
        serviciosCompletados: servicios,
        destacada: destacada,
        cancelacionesTardias: cancelaciones,
        resenas: [
          ResenaPublica(
            id: 'r1',
            estrellas: 5,
            autorNombre: 'María Alejandra',
            comentario: 'Dejó todo impecable.',
            respuesta: respuestas['r1'],
          ),
        ],
      );

  @override
  Future<void> responder({
    required String calificacionId,
    required String texto,
  }) async {
    llamadas++;
    respuestas[calificacionId] = texto;
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

Widget _app(_ReputacionFalsa repo) => ProviderScope(
      overrides: [
        miReputacionRepositoryProvider.overrideWithValue(repo),
        sesionProvider.overrideWith(_SesionFalsa.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const MiReputacionScreen(),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-31 c1: publica la respuesta y aparece debajo de la reseña',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _ReputacionFalsa();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Dejó todo impecable.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('responder-r1')));
    await tester.pumpAndSettle();

    expect(find.text('Responder a la reseña'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('campo-respuesta')),
      '¡Gracias, María! Fue un gusto.',
    );
    await tester.tap(find.byKey(const Key('publicar-respuesta')));
    await tester.pumpAndSettle();

    expect(repo.respuestas['r1'], '¡Gracias, María! Fue un gusto.');
    expect(find.text('Tu respuesta quedó publicada.'), findsOneWidget);
    expect(find.text('Tu respuesta'), findsOneWidget);
    expect(find.text('¡Gracias, María! Fue un gusto.'), findsOneWidget);
    expect(find.text('Editar respuesta'), findsOneWidget);
  });

  testWidgets('HU-31 c2: si ya respondió puede editarla, pero no agregar otra',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _ReputacionFalsa(respuestas: {'r1': 'Gracias'});
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // No hay un botón para responder de nuevo, solo para editar.
    expect(find.text('Responder'), findsNothing);
    await tester.tap(find.text('Editar respuesta'));
    await tester.pumpAndSettle();

    expect(find.text('Editar mi respuesta'), findsOneWidget);
    // El campo trae la respuesta anterior.
    expect(find.widgetWithText(TextField, 'Gracias'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('campo-respuesta')),
      'Gracias, ¡vuelvo cuando quieras!',
    );
    await tester.tap(find.byKey(const Key('publicar-respuesta')));
    await tester.pumpAndSettle();

    expect(repo.respuestas, {'r1': 'Gracias, ¡vuelvo cuando quieras!'});
    expect(find.text('Tu respuesta quedó actualizada.'), findsOneWidget);
    expect(find.text('Gracias, ¡vuelvo cuando quieras!'), findsOneWidget);
  });

  testWidgets('HU-31 c3: con más de 300 caracteres ve el límite y no se '
      'publica', (tester) async {
    _pantallaGrande(tester);
    final repo = _ReputacionFalsa();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('responder-r1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('campo-respuesta')),
      'a' * 301,
    );
    await tester.tap(find.byKey(const Key('publicar-respuesta')));
    await tester.pumpAndSettle();

    expect(
      find.text('La respuesta puede tener hasta 300 caracteres'),
      findsOneWidget,
    );
    expect(repo.llamadas, 0);
    // El diálogo sigue abierto para que la acorte.
    expect(find.text('Responder a la reseña'), findsOneWidget);
  });

  testWidgets('HU-61: muestra lo que le falta para ser destacada',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_ReputacionFalsa(servicios: 7, promedio: 4.7, cancelaciones: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sube de nivel'), findsOneWidget);
    expect(find.text('7 de 10 servicios completados'), findsOneWidget);
    expect(find.text('Promedio de 4,7 (mínimo 4,5)'), findsOneWidget);
    expect(
      find.text('1 cancelación tardía en los últimos 30 días'),
      findsOneWidget,
    );
    expect(find.text('Destacada'), findsNothing);
  });

  testWidgets('HU-61 c1: con la insignia la muestra', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(_ReputacionFalsa(destacada: true, servicios: 12, promedio: 4.9)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eres una trabajadora destacada'), findsOneWidget);
    expect(find.text('Destacada'), findsOneWidget);
  });

  testWidgets('la pantalla no se desborda en móvil (390x844)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_ReputacionFalsa(respuestas: {'r1': 'Ok'})));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
