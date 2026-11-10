import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/archivo_foto.dart';
import 'package:limpiaya/domain/entities/mi_verificacion.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/verificacion_pendiente.dart';
import 'package:limpiaya/domain/repositories/verificacion_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/trabajadora/tarjeta_verificacion_perfil.dart';
import 'package:limpiaya/presentation/screens/trabajadora/verificacion_identidad_screen.dart';

class _RepositorioFalso implements VerificacionRepository {
  _RepositorioFalso(this.ultima);

  final MiVerificacion? ultima;
  int enviadas = 0;

  @override
  Future<MiVerificacion?> miUltima() async => ultima;

  @override
  Future<void> enviar({
    required ArchivoFoto cedula,
    required ArchivoFoto selfie,
  }) async =>
      enviadas++;

  @override
  Future<List<VerificacionPendiente>> pendientes() async => const [];

  @override
  Future<void> aprobar(String id) async {}

  @override
  Future<void> rechazar(String id, String motivo) async {}
}

class _SesionTrabajadora extends SesionNotifier {
  _SesionTrabajadora(this.verificacion);

  final String? verificacion;

  @override
  Future<Sesion?> build() async => Sesion(
        id: 't-1',
        rol: RolUsuario.trabajadora,
        nombre: 'Carmen Pérez',
        perfilCompleto: true,
        verificacion: verificacion,
      );
}

MiVerificacion _verificacion(EstadoVerificacion estado, {String? motivo}) =>
    MiVerificacion(
      estado: estado,
      motivoRechazo: motivo,
      enviada: DateTime(2026, 10, 28, 9),
    );

Widget _app(
  _RepositorioFalso repo, {
  String? verificacion,
  Widget home = const VerificacionIdentidadScreen(),
}) {
  return ProviderScope(
    overrides: [
      verificacionRepositoryProvider.overrideWithValue(repo),
      sesionProvider.overrideWith(() => _SesionTrabajadora(verificacion)),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(body: home),
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

  testWidgets('sin verificación muestra las dos cajas para subir fotos',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(null)));
    await tester.pumpAndSettle();

    expect(find.text('Verifica tu identidad'), findsOneWidget);
    expect(find.text('Tus documentos son privados.'), findsOneWidget);
    expect(find.text('Foto de tu cédula'), findsOneWidget);
    expect(find.text('Selfie sosteniendo tu cédula'), findsOneWidget);
    expect(find.text('Enviar a revisión'), findsOneWidget);
  });

  testWidgets('enviar sin fotos pide la cédula y no envía nada',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(null);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar a revisión'));
    await tester.pumpAndSettle();

    expect(find.text('Sube la foto de tu cédula'), findsOneWidget);
    expect(repo.enviadas, 0);
  });

  testWidgets('HU-21 c1: en revisión muestra "Recibimos tus documentos"',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      _RepositorioFalso(_verificacion(EstadoVerificacion.enRevision)),
      verificacion: 'en_revision',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Recibimos tus documentos'), findsOneWidget);
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.text('Enviar a revisión'), findsNothing);
  });

  testWidgets('HU-21 c3: rechazada muestra el motivo y deja subir otra foto',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      _RepositorioFalso(_verificacion(
        EstadoVerificacion.rechazada,
        motivo: 'La foto de la cédula no se lee',
      )),
      verificacion: 'rechazada',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tu verificación fue rechazada'), findsOneWidget);
    expect(find.text('Motivo: La foto de la cédula no se lee'), findsOneWidget);
    expect(find.text('Enviar a revisión'), findsOneWidget);
  });

  testWidgets('HU-21 c2: aprobada muestra que la identidad está verificada',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      _RepositorioFalso(_verificacion(EstadoVerificacion.aprobada)),
      verificacion: 'aprobada',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tu identidad está verificada'), findsOneWidget);
  });

  testWidgets('en el teléfono el formulario cabe sin desbordarse',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_RepositorioFalso(null)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Enviar a revisión'), findsOneWidget);
  });

  group('Mi perfil', () {
    testWidgets('HU-21 c2: aprobada muestra la insignia "Identidad verificada"',
        (tester) async {
      await tester.pumpWidget(_app(
        _RepositorioFalso(null),
        verificacion: 'aprobada',
        home: const TarjetaVerificacionPerfil(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Identidad verificada'), findsOneWidget);
    });

    testWidgets('HU-21 c3: rechazada muestra el motivo y "Subir otra foto"',
        (tester) async {
      await tester.pumpWidget(_app(
        _RepositorioFalso(_verificacion(
          EstadoVerificacion.rechazada,
          motivo: 'La selfie está oscura',
        )),
        verificacion: 'rechazada',
        home: const TarjetaVerificacionPerfil(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Motivo: La selfie está oscura'), findsOneWidget);
      expect(find.text('Subir otra foto'), findsOneWidget);
    });

    testWidgets('sin verificar ofrece "Verificar mi identidad"',
        (tester) async {
      await tester.pumpWidget(_app(
        _RepositorioFalso(null),
        home: const TarjetaVerificacionPerfil(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Verificar mi identidad'), findsOneWidget);
    });
  });
}
