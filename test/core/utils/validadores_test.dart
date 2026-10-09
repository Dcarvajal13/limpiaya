import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/utils/validadores.dart';

void main() {
  group('Validadores.email', () {
    test('acepta un correo válido', () {
      expect(Validadores.email('ana@correo.com'), isNull);
    });

    test('rechaza vacío y correos sin formato', () {
      expect(Validadores.email(''), isNotNull);
      expect(Validadores.email('ana@'), isNotNull);
      expect(Validadores.email('ana.correo.com'), isNotNull);
    });
  });

  group('Validadores.telefono (HU-01, criterio 3)', () {
    test('acepta 04XX-XXXXXXX', () {
      expect(Validadores.telefono('0414-1234567'), isNull);
    });

    test('rechaza otros formatos', () {
      expect(Validadores.telefono('04141234567'), isNotNull);
      expect(Validadores.telefono('0212-1234567'), isNotNull);
      expect(Validadores.telefono('0414-123'), isNotNull);
    });
  });

  group('Validadores.password (HU-01, criterio 4)', () {
    test('exige mínimo 8 caracteres', () {
      expect(Validadores.password('1234567'), 'Mínimo 8 caracteres');
      expect(Validadores.password('12345678'), isNull);
    });
  });
}
