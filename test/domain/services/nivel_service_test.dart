import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/postulante.dart';
import 'package:limpiaya/domain/services/nivel_service.dart';

Postulante _p(String id, {bool destacada = false}) => Postulante(
      postulacionId: id,
      trabajadoraId: 't$id',
      nombre: 'Trabajadora $id',
      estado: EstadoPostulacion.pendiente,
      fecha: DateTime(2026, 11, 1),
      destacada: destacada,
    );

void main() {
  group('HU-61 c1 y c3 · cumple', () {
    test('10 servicios, 4,5 y sin cancelaciones tardías: sí', () {
      expect(
        NivelService.cumple(
          servicios: 10,
          promedio: 4.5,
          cancelacionesTardias: 0,
        ),
        isTrue,
      );
    });

    test('con 9 servicios todavía no', () {
      expect(
        NivelService.cumple(
          servicios: 9,
          promedio: 5,
          cancelacionesTardias: 0,
        ),
        isFalse,
      );
    });

    test('c3 · con promedio 4,4 no (o la pierde)', () {
      expect(
        NivelService.cumple(
          servicios: 20,
          promedio: 4.4,
          cancelacionesTardias: 0,
        ),
        isFalse,
      );
    });

    test('con una cancelación tardía reciente no', () {
      expect(
        NivelService.cumple(
          servicios: 20,
          promedio: 5,
          cancelacionesTardias: 1,
        ),
        isFalse,
      );
    });

    test('sin promedio no', () {
      expect(
        NivelService.cumple(
          servicios: 10,
          promedio: null,
          cancelacionesTardias: 0,
        ),
        isFalse,
      );
    });
  });

  test('HU-61 c2 · las destacadas primero, respetando el orden de llegada',
      () {
    final ordenadas = NivelService.ordenarPostulantes([
      _p('1'),
      _p('2', destacada: true),
      _p('3'),
      _p('4', destacada: true),
    ]);
    expect([for (final p in ordenadas) p.postulacionId], ['2', '4', '1', '3']);
  });

  test('textos de progreso', () {
    expect(
      NivelService.progresoServicios(7),
      '7 de 10 servicios completados',
    );
    expect(
      NivelService.progresoServicios(15),
      '10 de 10 servicios completados',
    );
    expect(
      NivelService.progresoPromedio(4.62),
      'Promedio de 4,6 (mínimo 4,5)',
    );
    expect(
      NivelService.progresoPromedio(null),
      'Aún sin promedio (mínimo 4,5)',
    );
    expect(
      NivelService.progresoCancelaciones(0),
      'Sin cancelaciones tardías en 30 días',
    );
    expect(
      NivelService.progresoCancelaciones(2),
      '2 cancelaciones tardías en los últimos 30 días',
    );
  });
}
