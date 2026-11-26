import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/aviso.dart';
import 'package:limpiaya/domain/entities/correo_aviso.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/repositories/aviso_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/comun/avisos_screen.dart';
import 'package:limpiaya/presentation/widgets/campana_avisos.dart';

class _AvisosFalsos implements AvisoRepository {
  _AvisosFalsos({this.avisos = const [], this.correos = const []});

  final List<Aviso> avisos;
  final List<CorreoAviso> correos;
  final marcados = <String>[];
  bool marcoTodos = false;
  bool? ultimaPreferenciaCorreo;

  @override
  Future<List<Aviso>> misAvisos() async => avisos;

  @override
  Stream<List<Aviso>> streamAvisos() => Stream.value(avisos);

  @override
  Future<void> marcarLeido(String avisoId) async => marcados.add(avisoId);

  @override
  Future<void> marcarTodosLeidos() async => marcoTodos = true;

  @override
  Future<List<CorreoAviso>> misCorreos() async => correos;

  @override
  Future<void> actualizarAvisosCorreo(bool activo) async =>
      ultimaPreferenciaCorreo = activo;
}

class _SesionFija extends SesionNotifier {
  _SesionFija(this._sesion);
  final Sesion _sesion;

  @override
  Future<Sesion?> build() async => _sesion;
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  final sesion = const Sesion(
    id: 'u1',
    rol: RolUsuario.cliente,
    nombre: 'María Rodríguez',
    perfilCompleto: true,
    avisosCorreo: true,
  );

  testWidgets('HU-50 · la campana muestra contador de no leídos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: const Scaffold(
          body: Center(child: CampanaAvisos(noLeidosManual: 3)),
        ),
      ),
    );

    expect(find.byKey(const Key('campana-avisos')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('HU-50 · muestra avisos y permite marcar todos como leídos',
      (tester) async {
    final repo = _AvisosFalsos(
      avisos: [
        Aviso(
          id: 'a1',
          tipo: TipoAviso.postulacion,
          titulo: 'Nueva postulación',
          mensaje: 'Carmen se postuló a tu solicitud.',
          creadoEn: DateTime(2026, 11, 25, 10),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith(() => _SesionFija(sesion)),
          avisoRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(theme: AppTheme.claro, home: const AvisosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva postulación'), findsOneWidget);
    expect(find.text('En la app (1)'), findsOneWidget);

    await tester.tap(find.text('Marcar todos'));
    await tester.pumpAndSettle();

    expect(repo.marcoTodos, isTrue);
  });

  testWidgets('HU-49 · pestaña Por correo muestra eventos, historial y switch',
      (tester) async {
    final repo = _AvisosFalsos(
      correos: [
        CorreoAviso(
          id: 'c1',
          tipo: TipoCorreoAviso.recordatorio24h,
          asunto: 'Recordatorio: tu servicio es en 24 horas · LimpiaYa',
          cuerpo: 'Tu servicio comienza mañana a las 9:00 a. m.',
          estado: EstadoCorreoAviso.pendiente,
          programadoPara: DateTime(2026, 11, 26, 9),
          creadoEn: DateTime(2026, 11, 25, 9),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sesionProvider.overrideWith(() => _SesionFija(sesion)),
          avisoRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(theme: AppTheme.claro, home: const AvisosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Por correo'));
    await tester.pumpAndSettle();

    expect(find.text('Avisos por correo electrónico'), findsOneWidget);
    expect(find.text('Recordatorio 24 h'), findsOneWidget);
    expect(
      find.text('Recordatorio: tu servicio es en 24 horas · LimpiaYa'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repo.ultimaPreferenciaCorreo, isFalse);
  });
}
