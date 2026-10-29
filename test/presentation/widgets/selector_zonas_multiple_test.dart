import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/presentation/widgets/selector_zonas_multiple.dart';

const _zonas = [
  Zona(id: 1, nombre: 'Sabana Grande', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 2, nombre: 'La Florida', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 3, nombre: 'San Bernardino', municipio: 'Libertador', parroquia: 'San Bernardino'),
  Zona(id: 4, nombre: 'Altamira', municipio: 'Chacao', parroquia: 'Chacao'),
  Zona(id: 5, nombre: 'Los Palos Grandes', municipio: 'Chacao', parroquia: 'Chacao'),
];

class _Prueba extends StatefulWidget {
  const _Prueba({this.iniciales = const {}});

  final Set<int> iniciales;

  @override
  State<_Prueba> createState() => _PruebaState();
}

class _PruebaState extends State<_Prueba> {
  late Set<int> elegidas = {...widget.iniciales};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SelectorZonasMultiple(
            zonas: _zonas,
            seleccionadas: elegidas,
            onChanged: (nuevas) => setState(() => elegidas = nuevas),
          ),
          Text('elegidas: ${(elegidas.toList()..sort()).join(',')}'),
        ],
      ),
    );
  }
}

Future<void> _abrir(WidgetTester tester, {Set<int> iniciales = const {}}) {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: Scaffold(body: _Prueba(iniciales: iniciales)),
    ),
  );
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('muestra los municipios como lista, no todas las zonas juntas',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    expect(find.text('Chacao'), findsOneWidget);
    expect(find.text('Libertador'), findsOneWidget);
    // Las urbanizaciones no se ven hasta abrir su municipio.
    expect(find.text('Sabana Grande'), findsNothing);

    await tester.tap(find.text('Libertador'));
    await tester.pumpAndSettle();

    expect(find.text('Parroquia El Recreo'), findsOneWidget);
    expect(find.text('Parroquia San Bernardino'), findsOneWidget);
    expect(find.text('Sabana Grande'), findsOneWidget);
  });

  testWidgets('elige una urbanización y la muestra arriba', (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Libertador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zona-1')));
    await tester.pumpAndSettle();

    expect(find.text('elegidas: 1'), findsOneWidget);
    expect(find.text('Elegiste 1 urbanización'), findsOneWidget);
    expect(find.byKey(const Key('elegida-1')), findsOneWidget);
    expect(find.text('1 de 3 elegidas'), findsOneWidget);
  });

  testWidgets('"Seleccionar todas" elige toda la parroquia', (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Libertador'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('todas-Libertador-El Recreo')));
    await tester.pumpAndSettle();

    expect(find.text('elegidas: 1,2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('todas-Libertador-El Recreo')),
        matching: find.text('Quitar todas'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('la casilla del municipio elige y quita todo el municipio',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('todo-Chacao')));
    await tester.pumpAndSettle();
    expect(find.text('elegidas: 4,5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('todo-Chacao')));
    await tester.pumpAndSettle();
    expect(find.text('elegidas: '), findsOneWidget);
  });

  testWidgets('la × de una elegida la quita', (tester) async {
    await _abrir(tester, iniciales: {3, 4});
    await tester.pumpAndSettle();

    expect(find.text('Elegiste 2 urbanizaciones'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar Altamira'));
    await tester.pumpAndSettle();

    expect(find.text('elegidas: 3'), findsOneWidget);
  });

  testWidgets('búsqueda: filtra y muestra lo que coincide ya abierto',
      (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar-zonas')), 'grande');
    await tester.pumpAndSettle();

    // Sin abrir ningún municipio aparecen las dos que coinciden.
    expect(find.text('Sabana Grande'), findsOneWidget);
    expect(find.text('Los Palos Grandes'), findsOneWidget);
    expect(find.text('Altamira'), findsNothing);
    expect(find.text('Libertador · Parroquia El Recreo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('zona-5')));
    await tester.pumpAndSettle();
    expect(find.text('elegidas: 5'), findsOneWidget);
  });

  testWidgets('búsqueda: sin resultados lo dice', (tester) async {
    await _abrir(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('buscar-zonas')), 'maracay');
    await tester.pumpAndSettle();

    expect(find.textContaining('No encontramos "maracay"'), findsOneWidget);

    // La × borra la búsqueda y vuelve la lista por municipios.
    await tester.tap(find.byTooltip('Borrar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('Chacao'), findsOneWidget);
  });
}
