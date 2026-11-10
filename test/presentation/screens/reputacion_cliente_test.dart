import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/perfil_cliente_publico.dart';
import 'package:limpiaya/domain/entities/perfil_publico.dart';
import 'package:limpiaya/domain/repositories/cliente_publico_repository.dart';
import 'package:limpiaya/presentation/screens/trabajadora/caja_cliente.dart';
import 'package:limpiaya/presentation/screens/trabajadora/perfil_cliente_publico_screen.dart';

class _ClienteFalso implements ClientePublicoRepository {
  _ClienteFalso(this.datos);

  final PerfilClientePublico? datos;

  @override
  Future<PerfilClientePublico?> perfil(String clienteId) async => datos;
}

const _conResenas = PerfilClientePublico(
  id: 'c-1',
  nombre: 'María Alejandra',
  promedio: 4.8,
  totalResenas: 3,
  serviciosCompletados: 3,
  resenas: [
    ResenaPublica(
      estrellas: 5,
      autorNombre: 'Carmen Pérez',
      comentario: 'Muy amable, pagó puntual.',
    ),
  ],
);

const _nuevo = PerfilClientePublico(id: 'c-2', nombre: 'Luis Rangel');

/// La caja dentro de un router: tocarla abre el perfil del cliente.
Widget _appCaja(PerfilClientePublico? datos) {
  final router = GoRouter(
    initialLocation: '/detalle',
    routes: [
      GoRoute(
        path: '/detalle',
        builder: (context, state) => const Scaffold(
          body: CajaCliente(clienteId: 'c-1'),
        ),
      ),
      GoRoute(
        path: '/trabajadora/clientes/:id',
        builder: (context, state) => PerfilClientePublicoScreen(
          clienteId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      clientePublicoRepositoryProvider.overrideWithValue(_ClienteFalso(datos)),
    ],
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

Widget _appPerfil(PerfilClientePublico? datos) => ProviderScope(
      overrides: [
        clientePublicoRepositoryProvider
            .overrideWithValue(_ClienteFalso(datos)),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const PerfilClientePublicoScreen(clienteId: 'c-1'),
      ),
    );

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-46 c1: muestra el promedio y los servicios completados',
      (tester) async {
    await tester.pumpWidget(_appCaja(_conResenas));
    await tester.pumpAndSettle();

    expect(find.text('El cliente'), findsOneWidget);
    expect(find.text('María Alejandra'), findsOneWidget);
    expect(find.text('★ 4,8 · 3 servicios completados'), findsOneWidget);
  });

  testWidgets('HU-46 c2: sin calificaciones dice "Cliente nuevo"',
      (tester) async {
    await tester.pumpWidget(_appCaja(_nuevo));
    await tester.pumpAndSettle();

    expect(find.text('Luis Rangel'), findsOneWidget);
    expect(find.text('Cliente nuevo'), findsOneWidget);
  });

  testWidgets('HU-46 c3: al tocar el nombre abre su perfil con las reseñas',
      (tester) async {
    tester.view.physicalSize = const Size(1100, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_appCaja(_conResenas));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('abrir-perfil-cliente')));
    await tester.pumpAndSettle();

    expect(find.text('Perfil del cliente'), findsOneWidget);
    expect(find.text('Lo que dicen otras trabajadoras'), findsOneWidget);
    expect(find.text('Carmen Pérez'), findsOneWidget);
    expect(find.text('Muy amable, pagó puntual.'), findsOneWidget);
    expect(find.text('· 3 reseñas'), findsOneWidget);
  });

  testWidgets('HU-46 perfil de un cliente nuevo y sin datos privados',
      (tester) async {
    await tester.pumpWidget(_appPerfil(_nuevo));
    await tester.pumpAndSettle();

    expect(find.text('Cliente nuevo'), findsOneWidget);
    expect(find.text('Todavía no hay reseñas para mostrar.'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    expect(find.textContaining('0414'), findsNothing);
  });

  testWidgets('si el cliente no existe lo dice', (tester) async {
    await tester.pumpWidget(_appPerfil(null));
    await tester.pumpAndSettle();

    expect(find.text('No encontramos a este cliente'), findsOneWidget);
  });

  testWidgets('el perfil renderiza sin desbordamiento en móvil (390x844)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_appPerfil(_conResenas));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
