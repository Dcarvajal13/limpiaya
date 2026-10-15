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

  group('Validadores.tarifa (HU-04, criterio 5)', () {
    test('vacío está bien (es opcional)', () {
      expect(Validadores.tarifa(''), isNull);
      expect(Validadores.tarifa(null), isNull);
      expect(Validadores.tarifa('   '), isNull);
    });

    test('acepta números, con punto o coma', () {
      expect(Validadores.tarifa('5'), isNull);
      expect(Validadores.tarifa('12.5'), isNull);
      expect(Validadores.tarifa('7,5'), isNull);
    });

    test('rechaza lo que no es número', () {
      expect(Validadores.tarifa('gratis'), isNotNull);
      expect(Validadores.tarifa('-3'), isNotNull);
    });
  });

  group('Validadores.anosExperiencia (HU-04)', () {
    test('vacío está bien (es opcional)', () {
      expect(Validadores.anosExperiencia(''), isNull);
      expect(Validadores.anosExperiencia(null), isNull);
    });

    test('acepta años entre 0 y 70', () {
      expect(Validadores.anosExperiencia('0'), isNull);
      expect(Validadores.anosExperiencia('30'), isNull);
      expect(Validadores.anosExperiencia('70'), isNull);
    });

    test('rechaza fuera del rango y texto', () {
      expect(Validadores.anosExperiencia('71'), isNotNull);
      expect(Validadores.anosExperiencia('-1'), isNotNull);
      expect(Validadores.anosExperiencia('dos'), isNotNull);
    });
  });
}
