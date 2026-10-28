import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/services/postulacion_service.dart';

void main() {
  // HU-12 c3 · "Dado que tengo un servicio Asignado que se cruza en fecha y
  // hora, cuando intento postularme, entonces veo 'Ya tienes un servicio en
  // ese horario' y no se registra."
  group('HU-12 c3 · cruce de horarios', () {
    final inicio = DateTime(2026, 11, 2, 9);
    final fin = DateTime(2026, 11, 2, 13);

    test('sin servicios asignados nunca hay cruce', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: const [],
        ),
        isFalse,
      );
    });

    test('un servicio dentro del rango se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 2, 10), DateTime(2026, 11, 2, 11))],
        ),
        isTrue,
      );
    });

    test('un servicio que envuelve el rango se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 2, 8), DateTime(2026, 11, 2, 15))],
        ),
        isTrue,
      );
    });

    test('un servicio que empieza antes y termina dentro se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 2, 7), DateTime(2026, 11, 2, 10))],
        ),
        isTrue,
      );
    });

    test('un servicio que termina justo al empezar no se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 2, 5), DateTime(2026, 11, 2, 9))],
        ),
        isFalse,
      );
    });

    test('un servicio que empieza justo al terminar no se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 2, 13), DateTime(2026, 11, 2, 17))],
        ),
        isFalse,
      );
    });

    test('un servicio en otro día no se cruza', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [(DateTime(2026, 11, 3, 9), DateTime(2026, 11, 3, 13))],
        ),
        isFalse,
      );
    });

    test('con varios servicios basta que uno se cruce', () {
      expect(
        PostulacionService.seCruza(
          inicio: inicio,
          fin: fin,
          servicios: [
            (DateTime(2026, 11, 1, 9), DateTime(2026, 11, 1, 13)),
            (DateTime(2026, 11, 2, 12), DateTime(2026, 11, 2, 16)),
          ],
        ),
        isTrue,
      );
    });
  });

  // HU-26 c2 · "Dado que mi postulación ya fue Aceptada, cuando la abro,
  // entonces la opción 'Retirar' no está disponible".
  group('HU-26 c2 · solo se retira una postulación pendiente', () {
    test('pendiente se puede retirar', () {
      expect(PostulacionService.puedeRetirar(EstadoPostulacion.pendiente), isTrue);
    });

    test('aceptada, no seleccionada, retirada o cancelada no', () {
      for (final estado in [
        EstadoPostulacion.aceptada,
        EstadoPostulacion.noSeleccionada,
        EstadoPostulacion.retirada,
        EstadoPostulacion.solicitudCancelada,
      ]) {
        expect(
          PostulacionService.puedeRetirar(estado),
          isFalse,
          reason: 'estado ${estado.etiqueta}',
        );
      }
    });
  });

  // HU-12 c4 · "Dado que mi identidad no está verificada, cuando presiono
  // 'Postularme', entonces veo 'Verifica tu identidad para postularte'".
  group('HU-12 c4 · identidad', () {
    test('aprobada deja postularse', () {
      expect(PostulacionService.identidadAprobada('aprobada'), isTrue);
    });

    test('pendiente, en revisión, rechazada o sin dato no dejan', () {
      for (final estado in ['pendiente', 'en_revision', 'rechazada', null]) {
        expect(
          PostulacionService.identidadAprobada(estado),
          isFalse,
          reason: 'verificación "$estado"',
        );
      }
    });
  });
}
