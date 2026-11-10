import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/services/chat_service.dart';

void main() {
  group('HU-38 · validar un mensaje', () {
    test('vacío o solo espacios no se envía', () {
      expect(ChatService.validar(''), ChatService.mensajeVacio);
      expect(ChatService.validar('   \n '), ChatService.mensajeVacio);
    });

    test('hasta 500 caracteres se acepta', () {
      expect(ChatService.validar('a' * 500), isNull);
    });

    test('más de 500 caracteres se rechaza', () {
      expect(ChatService.validar('a' * 501), ChatService.mensajeLargo);
    });

    test('los espacios de los extremos no cuentan para el límite', () {
      expect(ChatService.validar('  ${'a' * 500}  '), isNull);
    });
  });

  group('HU-38 · cuándo está abierto el chat', () {
    final ahora = DateTime(2026, 11, 10, 12);

    test('un servicio asignado siempre tiene chat', () {
      expect(ChatService.chatAbierto(EstadoSolicitud.asignada), isTrue);
    });

    test('una solicitud publicada todavía no tiene chat', () {
      expect(ChatService.chatAbierto(EstadoSolicitud.publicada), isFalse);
    });

    test('completado hace 6 días sigue abierto', () {
      expect(
        ChatService.chatAbierto(
          EstadoSolicitud.completada,
          completadaEn: ahora.subtract(const Duration(days: 6)),
          ahora: ahora,
        ),
        isTrue,
      );
    });

    test('completado hace 7 días ya cerró', () {
      expect(
        ChatService.chatAbierto(
          EstadoSolicitud.completada,
          completadaEn: ahora.subtract(const Duration(days: 7)),
          ahora: ahora,
        ),
        isFalse,
      );
    });

    test('cancelado hace 8 días ya cerró', () {
      expect(
        ChatService.chatAbierto(
          EstadoSolicitud.cancelada,
          canceladaEn: ahora.subtract(const Duration(days: 8)),
          ahora: ahora,
        ),
        isFalse,
      );
    });

    test('sin fecha de cierre no se puede escribir', () {
      expect(
        ChatService.chatAbierto(EstadoSolicitud.completada),
        isFalse,
      );
    });
  });
}
