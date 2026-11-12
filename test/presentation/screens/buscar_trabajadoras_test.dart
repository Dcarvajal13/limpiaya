import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/perfil_publico.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/busqueda_trabajadoras_repository.dart';
import 'package:limpiaya/presentation/providers/mis_solicitudes_provider.dart';
import 'package:limpiaya/presentation/providers/publicar_solicitud_provider.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/cliente/buscar_trabajadoras_screen.dart';
import 'package:limpiaya/presentation/screens/trabajadora/tarjeta_solicitud.dart';

/// Filtra por zona como la vista (zona_ids) y guarda las invitaciones.
class _BusquedaFalsa implements BusquedaTrabajadorasRepository {
  _BusquedaFalsa(this.todas);

  final List<PerfilPublico> todas;
  final invitaciones = <(String, String)>[];

  @override
  Future<List<PerfilPublico>> buscar({int? zonaId}) async => [
        for (final t in todas)
          if (zonaId == null || t.zonaIds.contains(zonaId)) t,
      ];

  @override
  Future<void> invitar({
    required String solicitudId,
    required String trabajadoraId,
  }) async =>
      invitaciones.add((solicitudId, trabajadoraId));

  @override
  Future<List<({String solicitudId, String trabajadoraId})>>
      misInvitaciones() async => [
            for (final (s, t) in invitaciones)
              (solicitudId: s, trabajadoraId: t),
          ];
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

const _carmen = PerfilPublico(
  id: 't1',
  nombre: 'Carmen Pérez',
  verificada: true,
  promedio: 4.9,
  totalResenas: 12,
  serviciosCompletados: 12,
  destacada: true,
  zonas: ['Altamira'],
  zonaIds: [1],
);

const _marisol = PerfilPublico(
  id: 't2',
  nombre: 'Marisol Gómez',
  verificada: true,
  promedio: 4.3,
  totalResenas: 4,
  serviciosCompletados: 4,
  zonas: ['Petare'],
  zonaIds: [2],
);

const _yelitza = PerfilPublico(
  id: 't3',
  nombre: 'Yelitza Mora',
  verificada: true,
  zonas: ['Altamira', 'Petare'],
  zonaIds: [1, 2],
);

const _zonas = [
  Zona(id: 1, nombre: 'Altamira', municipio: 'Chacao'),
  Zona(id: 2, nombre: 'Petare', municipio: 'Sucre'),
  Zona(id: 3, nombre: 'El Hatillo', municipio: 'El Hatillo'),
];

Solicitud _publicada({int zona = 1}) => Solicitud(
      id: 's1',
      clienteId: 'c1',
      estado: EstadoSolicitud.publicada,
      tipo: TipoLimpieza.general,
      zonaId: zona,
      zona: zona == 1 ? 'Altamira' : 'Petare',
      inicio: DateTime.now().add(const Duration(days: 3)),
      horasEstimadas: 3,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 0,
    );

Widget _app(
  _BusquedaFalsa repo, {
  List<Solicitud> misSolicitudes = const [],
}) =>
    ProviderScope(
      overrides: [
        busquedaTrabajadorasRepositoryProvider.overrideWithValue(repo),
        sesionProvider.overrideWith(_SesionFalsa.new),
        zonasCatalogoProvider.overrideWith((ref) async => _zonas),
        misSolicitudesProvider.overrideWith((ref) async => misSolicitudes),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const BuscarTrabajadorasScreen(),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Si [a] aparece antes que [b] (más arriba, o a la izquierda en la misma
/// fila).
bool _antes(WidgetTester tester, String a, String b) {
  final pa = tester.getTopLeft(find.text(a));
  final pb = tester.getTopLeft(find.text(b));
  return pa.dy < pb.dy || (pa.dy == pb.dy && pa.dx < pb.dx);
}

Future<void> _elegirZona(WidgetTester tester, String opcion) async {
  await tester.tap(find.byType(DropdownButtonFormField<int?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-25 c1: al filtrar por zona solo salen las de esa zona',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_BusquedaFalsa([_carmen, _marisol, _yelitza])));
    await tester.pumpAndSettle();

    expect(find.text('3 trabajadoras'), findsOneWidget);

    await _elegirZona(tester, 'Petare · Sucre');

    expect(find.text('2 trabajadoras'), findsOneWidget);
    expect(find.text('Marisol Gómez'), findsOneWidget);
    expect(find.text('Yelitza Mora'), findsOneWidget);
    expect(find.text('Carmen Pérez'), findsNothing);
  });

  testWidgets('HU-25 c2: por calificación salen de mayor a menor promedio',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_BusquedaFalsa([_yelitza, _marisol, _carmen])));
    await tester.pumpAndSettle();

    expect(_antes(tester, 'Carmen Pérez', 'Marisol Gómez'), isTrue);
    expect(_antes(tester, 'Marisol Gómez', 'Yelitza Mora'), isTrue);
    expect(find.text('★ 4,9 · 12 reseñas'), findsOneWidget);
    expect(find.text('Nueva en la plataforma'), findsOneWidget);
    expect(find.text('Destacada'), findsOneWidget);
  });

  testWidgets('HU-25 c3: "Invitar" la invita a mi solicitud publicada',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _BusquedaFalsa([_carmen]);
    await tester.pumpWidget(_app(repo, misSolicitudes: [_publicada()]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitar-t1')));
    await tester.pumpAndSettle();

    expect(find.text('Invitar a Carmen'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmar-invitar')));
    await tester.pumpAndSettle();

    expect(repo.invitaciones, [('s1', 't1')]);
    expect(
      find.text(
        'Invitaste a Carmen. Verá tu solicitud marcada como «Te invitaron».',
      ),
      findsOneWidget,
    );
  });

  testWidgets('después de invitarla, su botón dice "Invitada"',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _BusquedaFalsa([_carmen, _marisol]);
    await tester.pumpWidget(_app(repo, misSolicitudes: [_publicada()]));
    await tester.pumpAndSettle();

    expect(find.text('Invitada'), findsNothing);

    await tester.tap(find.byKey(const Key('invitar-t1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmar-invitar')));
    await tester.pumpAndSettle();

    // Carmen quedó "Invitada"; Marisol sigue con "Invitar".
    expect(find.text('Invitada'), findsOneWidget);
    expect(find.text('Invitar'), findsOneWidget);

    // Si se vuelve a tocar, avisa que ya está invitada a esa solicitud.
    await tester.tap(find.byKey(const Key('invitar-t1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ya-invitada')), findsOneWidget);
    expect(repo.invitaciones, [('s1', 't1')]);
  });

  testWidgets('HU-25 c3: sin solicitudes publicadas pide publicar una',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _BusquedaFalsa([_carmen]);
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitar-t1')));
    await tester.pumpAndSettle();

    expect(find.text('Primero publica una solicitud'), findsOneWidget);
    expect(find.textContaining('necesitas una solicitud publicada'),
        findsOneWidget);
    expect(find.byKey(const Key('ir-a-publicar')), findsOneWidget);
    expect(repo.invitaciones, isEmpty);
  });

  testWidgets('HU-25 c3: no deja invitar a una solicitud de otra zona',
      (tester) async {
    _pantallaGrande(tester);
    final repo = _BusquedaFalsa([_carmen]);
    await tester.pumpWidget(_app(repo, misSolicitudes: [_publicada(zona: 2)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitar-t1')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ninguna de tus solicitudes publicadas'),
        findsOneWidget);
    expect(find.byKey(const Key('confirmar-invitar')), findsNothing);
  });

  testWidgets('HU-25 c4: sin resultados dice "No hay trabajadoras con esos '
      'filtros"', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(_BusquedaFalsa([_carmen, _marisol])));
    await tester.pumpAndSettle();

    await _elegirZona(tester, 'El Hatillo · El Hatillo');

    expect(find.text('No hay trabajadoras con esos filtros'), findsOneWidget);
    await tester.tap(find.text('Ver todas las zonas'));
    await tester.pumpAndSettle();
    expect(find.text('2 trabajadoras'), findsOneWidget);
  });

  testWidgets('HU-25 c3: la trabajadora ve la solicitud marcada "Te invitaron"',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: TarjetaSolicitud(
            solicitud: SolicitudDisponible(
              id: 's1',
              tipo: TipoLimpieza.general,
              zonaId: 1,
              zona: 'Altamira',
              inicio: DateTime.now().add(const Duration(days: 3)),
              horasEstimadas: 3,
              pagoOfrecido: 30,
              metodoPago: MetodoPago.pagoMovil,
              numPostulantes: 0,
              meInvitaron: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Te invitaron'), findsOneWidget);
  });

  testWidgets('la búsqueda no se desborda en móvil (390x844)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_BusquedaFalsa([_carmen, _marisol])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
