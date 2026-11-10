import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/services/arbol_zonas.dart';

const _zonas = [
  Zona(id: 1, nombre: 'Sabana Grande', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 2, nombre: 'La Florida', municipio: 'Libertador', parroquia: 'El Recreo'),
  Zona(id: 3, nombre: 'San Bernardino', municipio: 'Libertador', parroquia: 'San Bernardino'),
  Zona(id: 4, nombre: 'Altamira', municipio: 'Chacao', parroquia: 'Chacao'),
  Zona(id: 5, nombre: 'El Cafetal', municipio: 'Baruta', parroquia: 'El Cafetal'),
  Zona(id: 6, nombre: 'Las Mercedes', municipio: 'Baruta', parroquia: 'Nuestra Señora del Rosario'),
  Zona(id: 7, nombre: 'Terrazas del Ávila', municipio: 'Sucre', parroquia: 'Petare'),
  Zona(id: 8, nombre: 'La Urbina', municipio: 'Sucre', parroquia: 'Petare'),
  Zona(id: 9, nombre: 'Zona vieja'),
];

void main() {
  final arbol = ArbolZonas(_zonas);

  test('ordena los municipios y deja "Otras zonas" al final', () {
    expect(
      arbol.municipios,
      ['Baruta', 'Chacao', 'Libertador', 'Sucre', ArbolZonas.sinDato],
    );
  });

  test('cada municipio trae sus parroquias en orden', () {
    expect(arbol.parroquias('Libertador'), ['El Recreo', 'San Bernardino']);
    expect(arbol.parroquias('Chacao'), ['Chacao']);
    expect(arbol.parroquias('No existe'), isEmpty);
  });

  test('cada parroquia trae sus urbanizaciones (los acentos no desordenan)',
      () {
    expect(
      arbol.zonas('Libertador', 'El Recreo').map((z) => z.nombre),
      ['La Florida', 'Sabana Grande'],
    );
    expect(
      arbol.zonas('Sucre', 'Petare').map((z) => z.nombre),
      ['La Urbina', 'Terrazas del Ávila'],
    );
  });

  test('todas las urbanizaciones de un municipio', () {
    expect(
      arbol.zonasDelMunicipio('Baruta').map((z) => z.id),
      [5, 6],
    );
  });

  test('ubica una zona por su id', () {
    expect(arbol.ubicacion(3), ('Libertador', 'San Bernardino'));
    expect(arbol.ubicacion(9), (ArbolZonas.sinDato, ArbolZonas.sinDato));
    expect(arbol.ubicacion(99), isNull);
    expect(arbol.ubicacion(null), isNull);
  });

  test('lee la parroquia de una fila de Supabase', () {
    final zona = Zona.desdeFila({
      'id': 11,
      'nombre': 'Los Palos Grandes',
      'municipio': 'Chacao',
      'parroquia': 'Chacao',
    });
    expect(zona.parroquia, 'Chacao');
    expect(Zona.desdeFila({'id': 1, 'nombre': 'X'}).parroquia, '');
  });

  test('búsqueda: sin acentos, por urbanización, parroquia o municipio', () {
    expect(arbol.filtrar('avila').map((z) => z.id), [7]);
    expect(arbol.filtrar('  MERCEDES ').map((z) => z.id), [6]);
    // Por parroquia: Petare trae sus dos urbanizaciones.
    expect(arbol.filtrar('petare').map((z) => z.id), [8, 7]);
    // Por municipio.
    expect(arbol.filtrar('chacao').map((z) => z.id), [4]);
    expect(arbol.filtrar(''), isEmpty);
    expect(arbol.filtrar('maracay'), isEmpty);
  });

  test('búsqueda: primero las urbanizaciones que empiezan con lo escrito',
      () {
    // "La Florida", "La Urbina" y "Las Mercedes" empiezan con "la";
    // "Terrazas del Ávila" solo lo contiene, así que va al final.
    expect(arbol.filtrar('la').map((z) => z.id), [2, 8, 6, 7]);
  });
}
