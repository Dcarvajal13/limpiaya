import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/services/respuesta_service.dart';

void main() {
  test('HU-31 · una respuesta normal es válida', () {
    expect(RespuestaService.validar('¡Gracias, María!'), isNull);
  });

  test('HU-31 · vacía o solo espacios no se publica', () {
    expect(RespuestaService.validar(''), RespuestaService.mensajeVacia);
    expect(RespuestaService.validar('   '), RespuestaService.mensajeVacia);
    expect(RespuestaService.validar(null), RespuestaService.mensajeVacia);
  });

  test('HU-31 c3 · hasta 300 caracteres sí; 301 no', () {
    expect(RespuestaService.validar('a' * 300), isNull);
    expect(RespuestaService.validar('a' * 301), RespuestaService.mensajeLimite);
  });

  test('HU-31 c3 · los espacios de los extremos no cuentan', () {
    expect(RespuestaService.validar('  ${'a' * 300}  '), isNull);
  });
}
