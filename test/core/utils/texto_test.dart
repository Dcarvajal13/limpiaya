import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/utils/texto.dart';

void main() {
  group('Texto.iniciales', () {
    test('toma la primera letra de las dos primeras palabras', () {
      expect(Texto.iniciales('María Alejandra Rodríguez'), 'MA');
      expect(Texto.iniciales('carmen pérez'), 'CP');
    });

    test('funciona con un solo nombre, espacios extra y tildes', () {
      expect(Texto.iniciales('  Ángela  '), 'Á');
      expect(Texto.iniciales('Yelitza   Rojas'), 'YR');
    });

    test('devuelve ? si no hay nombre', () {
      expect(Texto.iniciales('   '), '?');
    });
  });
}
