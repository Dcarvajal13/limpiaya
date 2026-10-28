import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/verificacion_pendiente.dart';
import 'package:limpiaya/domain/repositories/verificacion_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/admin/admin_inicio_screen.dart';

class _RepositorioFalso implements VerificacionRepository {
  _RepositorioFalso(this.lista);

  List<VerificacionPendiente> lista;
  final aprobadas = <String>[];
  final rechazadas = <String, String>{};

  @override
  Future<List<VerificacionPendiente>> pendientes() async => lista;

  @override
  Future<void> aprobar(String id) async {
    aprobadas.add(id);
    lista = [for (final v in lista) if (v.id != id) v];
  }

  @override
  Future<void> rechazar(String id, String motivo) async {
    rechazadas[id] = motivo;
    lista = [for (final v in lista) if (v.id != id) v];
  }
}

class _SesionAdmin extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'admin-1',
        rol: RolUsuario.admin,
        nombre: 'admin',
        perfilCompleto: true,
      );
}

// Sin URLs de fotos: en las pruebas no hay internet.
VerificacionPendiente _verificacion(String id, String nombre, DateTime enviada) =>
    VerificacionPendiente(
      id: id,
      trabajadoraId: 't-$id',
      nombre: nombre,
      telefono: '0414-1234567',
      enviada: enviada,
      cuentaCreada: DateTime(2026, 10, 2),
    );

Widget _app(_RepositorioFalso repositorio) {
  return ProviderScope(
    overrides: [
      verificacionRepositoryProvider.overrideWithValue(repositorio),
      sesionProvider.overrideWith(_SesionAdmin.new),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const AdminInicioScreen(),
    ),
  );
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  final lista = [
    _verificacion('v1', 'Marisol Gómez', DateTime(2026, 10, 4, 9, 20)),
    _verificacion('v2', 'Andreína Silva', DateTime(2026, 10, 5, 10, 20)),
  ];

  testWidgets(
    'HU-33 c1: muestra la cola en orden, con fotos y datos de la cuenta',
    (tester) async {
      _pantallaGrande(tester);
      await tester.pumpWidget(_app(_RepositorioFalso(lista)));
      await tester.pumpAndSettle();

      expect(find.text('Verificaciones pendientes'), findsOneWidget);
      // La primera de la lista es la más antigua y es la que se abre.
      final primera = tester.getTopLeft(find.text('Enviada 4 oct. · 9:20 a. m.'));
      final segunda = tester.getTopLeft(find.text('Enviada 5 oct. · 10:20 a. m.'));
      expect(primera.dy, lessThan(segunda.dy));
      expect(find.text('Marisol Gómez'), findsNWidgets(2)); // fila + detalle
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.text('Cuenta creada el 2 de octubre de 2026'), findsOneWidget);
      expect(find.text('Foto de la cédula'), findsOneWidget);
      expect(find.text('Selfie sosteniendo la cédula'), findsOneWidget);
    },
  );

  testWidgets('HU-33 c2: aprobar pide confirmación y aprueba', (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(lista);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aprobar identidad'));
    await tester.pumpAndSettle();
    expect(find.text('¿Aprobar esta identidad?'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.aprobadas, ['v1']);
    expect(find.text('Identidad aprobada. Marisol Gómez ya puede postularse.'),
        findsOneWidget);
    // Se recarga la cola: ahora la primera es la siguiente.
    expect(find.text('Andreína Silva'), findsNWidgets(2));
  });

  testWidgets('HU-33 c3: rechazar sin motivo muestra "Indica el motivo"',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(lista);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();

    expect(find.text('Indica el motivo'), findsOneWidget);
    expect(find.text('¿Rechazar esta verificación?'), findsNothing);
    expect(repo.rechazadas, isEmpty);
  });

  testWidgets('rechazar con motivo pide confirmación y guarda el motivo',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _RepositorioFalso(lista);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'La cédula no se lee');
    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Rechazar esta verificación?'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.rechazadas, {'v1': 'La cédula no se lee'});
    expect(find.text('Verificación rechazada.'), findsOneWidget);
  });

  testWidgets('elegir otra fila muestra sus datos', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(lista)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Andreína Silva'));
    await tester.pumpAndSettle();

    expect(find.text('Andreína Silva'), findsNWidgets(2));
    expect(find.text('Marisol Gómez'), findsOneWidget); // solo en la lista
  });

  testWidgets('sin verificaciones muestra el estado vacío', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_RepositorioFalso(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No hay verificaciones pendientes'), findsOneWidget);
  });

  testWidgets('en el teléfono también se puede revisar', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_RepositorioFalso(lista)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aprobar identidad'), findsOneWidget);
    expect(find.text('Rechazar'), findsOneWidget);
  });
}
