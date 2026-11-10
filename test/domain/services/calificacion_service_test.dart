import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/motivo_calificacion_baja.dart';
import 'package:limpiaya/domain/services/calificacion_service.dart';

void main() {
  group('HU-29 c2 · estrellas', () {
    test('de 1 a 5 son válidas', () {
      for (var i = 1; i <= 5; i++) {
        expect(CalificacionService.estrellasValidas(i), isTrue, reason: '$i');
      }
    });

    test('sin elegir, 0 o más de 5 no', () {
      expect(CalificacionService.estrellasValidas(null), isFalse);
      expect(CalificacionService.estrellasValidas(0), isFalse);
      expect(CalificacionService.estrellasValidas(6), isFalse);
    });
  });

  group('HU-30 c2 · motivo con 1 o 2 estrellas', () {
    test('1 y 2 estrellas piden motivo; 3 a 5 no', () {
      expect(CalificacionService.requiereMotivo(1), isTrue);
      expect(CalificacionService.requiereMotivo(2), isTrue);
      expect(CalificacionService.requiereMotivo(3), isFalse);
      expect(CalificacionService.requiereMotivo(5), isFalse);
      expect(CalificacionService.requiereMotivo(null), isFalse);
    });

    test('falta el motivo solo si se pide y no se eligió', () {
      expect(CalificacionService.faltaMotivo(2, null), isTrue);
      expect(
        CalificacionService.faltaMotivo(2, MotivoCalificacionBaja.trato),
        isFalse,
      );
      expect(CalificacionService.faltaMotivo(4, null), isFalse);
    });
  });

  group('comentario opcional', () {
    test('vacío o con solo espacios se guarda como sin comentario', () {
      expect(CalificacionService.limpiarComentario(null), isNull);
      expect(CalificacionService.limpiarComentario('   '), isNull);
    });

    test('se quitan los espacios de los extremos', () {
      expect(
        CalificacionService.limpiarComentario('  Muy puntual  '),
        'Muy puntual',
      );
    });
  });
}
