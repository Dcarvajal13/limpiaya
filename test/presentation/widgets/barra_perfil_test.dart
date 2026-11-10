import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/presentation/screens/cliente/barra_cliente.dart';
import 'package:limpiaya/presentation/screens/trabajadora/barra_trabajadora.dart';

/// Corrección del review: "Mi perfil" y el nombre eran dos botones para lo
/// mismo, y "Cerrar sesión" debía estar dentro del perfil.
Widget _app(Widget barra, String inicio) {
  Widget pantalla(String texto) =>
      Scaffold(body: Column(children: [barra, Text(texto)]));
  final router = GoRouter(
    initialLocation: inicio,
    routes: [
      GoRoute(
        path: Rutas.inicioTrabajadora,
        builder: (context, state) => pantalla('Trabajos'),
      ),
      GoRoute(
        path: Rutas.perfilTrabajadora,
        builder: (context, state) => pantalla('Pantalla perfil trabajadora'),
      ),
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => pantalla('Mis solicitudes'),
      ),
      GoRoute(
        path: Rutas.perfilCliente,
        builder: (context, state) => pantalla('Pantalla perfil cliente'),
      ),
    ],
  );
  return MaterialApp.router(theme: AppTheme.claro, routerConfig: router);
}

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('la barra de la trabajadora ya no tiene "Mi perfil" ni '
      '"Cerrar sesión"', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      const BarraTrabajadora(nombre: 'Derek Carvajal'),
      Rutas.inicioTrabajadora,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Trabajos'), findsWidgets);
    expect(find.text('Mis servicios'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('el nombre de la trabajadora abre su perfil', (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      const BarraTrabajadora(nombre: 'Derek Carvajal'),
      Rutas.inicioTrabajadora,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Derek'));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla perfil trabajadora'), findsOneWidget);
  });

  testWidgets('el nombre del cliente abre su perfil y no hay "Cerrar sesión"',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(
      const BarraCliente(nombre: 'Juana Pérez'),
      Rutas.inicioCliente,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsNothing);
    await tester.tap(find.byKey(const Key('acceso-perfil')));
    await tester.pumpAndSettle();

    expect(find.text('Pantalla perfil cliente'), findsOneWidget);
  });
}
