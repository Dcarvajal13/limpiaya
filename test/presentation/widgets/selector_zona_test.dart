import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/presentation/widgets/selector_zona.dart';

const _zonas = [
  Zona(id: 1, nombre: 'Sabana Grande', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 2, nombre: 'La Florida', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 3, nombre: 'San Bernardino', municipio: 'Libertador', parroquia: 'San Bernardino'),
  Zona(id: 4, nombre: 'Altamira', municipio: 'Chacao', parroquia: 'Chacao'),
  Zona(id: 5, nombre: 'Los Palos Grandes', municipio: 'Chacao', parroquia: 'Chacao'),
];

/// Pantalla mínima que guarda el valor elegido, como hacen los formularios.
class _Prueba extends StatefulWidget {
  const _Prueba({this.inicial});

  final int? inicial;

  @override
  State<_Prueba> createState() => _PruebaState();
}

class _PruebaState extends State<_Prueba> {
  late int? valor = widget.inicial;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SelectorZona(
          zonas: _zonas,
          valor: valor,
          onChanged: (v) => setState(() => valor = v),
        ),
        Text('valor: $valor'),
      ],
    );
  }
}

Future<void> _abrir(WidgetTester tester, {int? inicial, double ancho = 900}) {
  tester.view.physicalSize = Size(ancho, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _Prueba(inicial: inicial),
        ),
      ),
    ),
  );
}

Future<void> _elegir(WidgetTester tester, String campo, String opcion) async {
  await tester.tap(find.byKey(Key(campo)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('se elige en orden municipio, parroquia y urbanización',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    expect(find.text('Municipio'), findsOneWidget);
    expect(find.text('Parroquia'), findsOneWidget);
    expect(find.text('Urbanización'), findsOneWidget);
    expect(find.text('Primero el municipio'), findsOneWidget);

    await _elegir(tester, 'zona-municipio', 'Libertador');
    await _elegir(tester, 'zona-parroquia', 'San Bernardino');
    await _elegir(tester, 'zona-urbanizacion', 'San Bernardino');

    expect(find.text('valor: 3'), findsOneWidget);
  });

  testWidgets('si el municipio tiene una sola parroquia se elige sola',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await _elegir(tester, 'zona-municipio', 'Chacao');
    // La parroquia Chacao ya quedó elegida: se pasa directo a la urbanización.
    await _elegir(tester, 'zona-urbanizacion', 'Los Palos Grandes');

    expect(find.text('valor: 5'), findsOneWidget);
  });

  testWidgets('cambiar el municipio borra la urbanización elegida',
      (tester) async {
    await _abrir(tester, inicial: 1);
    await tester.pumpAndSettle();

    // Precargada: muestra los tres pasos de la zona guardada.
    expect(find.text('Libertador'), findsOneWidget);
    expect(find.text('El Recreo'), findsOneWidget);
    expect(find.text('Sabana Grande'), findsOneWidget);

    await _elegir(tester, 'zona-municipio', 'Chacao');

    expect(find.text('valor: null'), findsOneWidget);
    expect(find.text('Sabana Grande'), findsNothing);
  });

  testWidgets('en pantallas angostas los pasos van uno debajo del otro',
      (tester) async {
    await _abrir(tester, ancho: 390);
    await tester.pumpAndSettle();

    final municipio = tester.getTopLeft(find.byKey(const Key('zona-municipio')));
    final parroquia = tester.getTopLeft(find.byKey(const Key('zona-parroquia')));
    expect(parroquia.dy, greaterThan(municipio.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('búsqueda: "palos" sugiere Los Palos Grandes y llena los pasos',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar-zona')), 'palos');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('opcion-zona-5')), findsOneWidget);
    expect(find.text('Chacao · Parroquia Chacao'), findsOneWidget);

    await tester.tap(find.byKey(const Key('opcion-zona-5')));
    await tester.pumpAndSettle();

    expect(find.text('valor: 5'), findsOneWidget);
    // Municipio y parroquia quedaron elegidos solos.
    expect(find.text('Chacao'), findsWidgets);
    // La búsqueda se limpia para no confundir.
    expect(
      tester.widget<TextField>(find.byKey(const Key('buscar-zona'))).controller!.text,
      isEmpty,
    );
  });

  testWidgets('búsqueda: sin acentos también encuentra', (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar-zona')), 'recreo');
    await tester.pumpAndSettle();

    // Busca también por parroquia: El Recreo trae sus dos urbanizaciones.
    expect(find.byKey(const Key('opcion-zona-1')), findsOneWidget);
    expect(find.byKey(const Key('opcion-zona-2')), findsOneWidget);
    expect(find.byKey(const Key('opcion-zona-4')), findsNothing);
  });
}
