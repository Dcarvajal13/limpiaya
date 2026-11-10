import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/services/reputacion_service.dart';

void main() {
  group('HU-46 · ReputacionService.cliente', () {
    test('c1: con calificaciones muestra promedio y servicios', () {
      expect(
        ReputacionService.cliente(
          promedio: 4.8,
          totalResenas: 3,
          serviciosCompletados: 3,
        ),
        '★ 4,8 · 3 servicios completados',
      );
      expect(
        ReputacionService.cliente(
          promedio: 5,
          totalResenas: 1,
          serviciosCompletados: 1,
        ),
        '★ 5,0 · 1 servicio completado',
      );
    });

    test('c2: sin calificaciones es "Cliente nuevo"', () {
      expect(
        ReputacionService.cliente(
          promedio: null,
          totalResenas: 0,
          serviciosCompletados: 0,
        ),
        'Cliente nuevo',
      );
      // Completó servicios pero las reseñas todavía no son visibles.
      expect(
        ReputacionService.cliente(
          promedio: null,
          totalResenas: 0,
          serviciosCompletados: 2,
        ),
        'Cliente nuevo',
      );
    });
  });
}
