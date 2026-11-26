import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/aviso.dart';
import 'package:limpiaya/domain/entities/correo_aviso.dart';
import 'package:limpiaya/domain/services/aviso_service.dart';

void main() {
  group('HU-50 · campana de avisos', () {
    final ahora = DateTime(2026, 11, 25, 10);

    test('cuenta únicamente los avisos sin leer', () {
      final avisos = [
        Aviso(
          id: '1',
          tipo: TipoAviso.postulacion,
          titulo: 'Nueva postulación',
          mensaje: 'Carmen se postuló',
          creadoEn: ahora,
        ),
        Aviso(
          id: '2',
          tipo: TipoAviso.eleccion,
          titulo: 'Fuiste elegida',
          mensaje: 'María te eligió',
          creadoEn: ahora,
          leidoEn: ahora,
        ),
        Aviso(
          id: '3',
          tipo: TipoAviso.cancelacion,
          titulo: 'Servicio cancelado',
          mensaje: 'Cambio de planes',
          creadoEn: ahora,
        ),
      ];

      expect(AvisoService.contarNoLeidos(avisos), 2);
    });

    test('formatea el contador de la campana con tope 99+', () {
      expect(AvisoService.etiquetaContador(0), '');
      expect(AvisoService.etiquetaContador(5), '5');
      expect(AvisoService.etiquetaContador(99), '99');
      expect(AvisoService.etiquetaContador(120), '99+');
    });
  });

  group('HU-49 · avisos por correo', () {
    final ahora = DateTime(2026, 11, 25, 10);

    test('programa recordatorio 24 h solo si falta más de un día', () {
      final enTresDias = ahora.add(const Duration(days: 3));
      expect(
        AvisoService.fechaRecordatorio24h(enTresDias, ahora: ahora),
        enTresDias.subtract(const Duration(hours: 24)),
      );

      final enDoceHoras = ahora.add(const Duration(hours: 12));
      expect(
        AvisoService.fechaRecordatorio24h(enDoceHoras, ahora: ahora),
        isNull,
      );
    });

    test('cubre los 4 eventos de correo con asunto definido', () {
      for (final tipo in TipoCorreoAviso.values) {
        expect(AvisoService.asuntoPara(tipo), isNotEmpty);
      }
    });
  });
}
