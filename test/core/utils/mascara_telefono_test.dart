import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/router/recuperacion.dart';
import 'package:limpiaya/core/utils/mascara_telefono.dart';
import 'package:limpiaya/core/utils/validadores.dart';

void main() {
  group('Taller UX, H5 · máscara del teléfono', () {
    test('pone el guion solo después de los 4 primeros dígitos', () {
      expect(MascaraTelefono.formatear('0414'), '0414');
      expect(MascaraTelefono.formatear('04141'), '0414-1');
      expect(MascaraTelefono.formatear('04141234567'), '0414-1234567');
    });

    test('ignora espacios, puntos y guiones mal puestos', () {
      expect(MascaraTelefono.formatear('0414 123.45.67'), '0414-1234567');
      expect(MascaraTelefono.formatear('04-14-1234567'), '0414-1234567');
    });

    test('no deja escribir más de 11 dígitos', () {
      expect(MascaraTelefono.formatear('041412345678999'), '0414-1234567');
    });

    test('el resultado pasa la validación del registro', () {
      expect(Validadores.telefono(MascaraTelefono.formatear('04241234567')),
          isNull);
    });

    test('como formateador de campo deja el cursor al final', () {
      const mascara = MascaraTelefono();
      final resultado = mascara.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '04121234567'),
      );
      expect(resultado.text, '0412-1234567');
      expect(resultado.selection.baseOffset, resultado.text.length);
    });
  });

  group('HU-19 · enlace de recuperación', () {
    test('vuelve a la raíz de la misma app con ?recuperar=1', () {
      expect(
        Recuperacion.enlaceDeRegreso(
            Uri.parse('http://localhost:54116/#/recuperar')),
        'http://localhost:54116/?recuperar=1',
      );
      expect(
        Recuperacion.enlaceDeRegreso(
            Uri.parse('https://limpiaya.web.app/#/login')),
        'https://limpiaya.web.app/?recuperar=1',
      );
    });

    test('reconoce cuando la app se abrió desde el enlace', () {
      expect(
        Recuperacion.vieneDelEnlace(
            Uri.parse('http://localhost:5000/?recuperar=1&code=abc')),
        isTrue,
      );
      expect(Recuperacion.vieneDelEnlace(Uri.parse('http://localhost:5000/')),
          isFalse);
    });
  });

  group('HU-19 · enlace vencido', () {
    test('explica que el enlace venció o ya se usó', () {
      final mensaje = Recuperacion.errorDelEnlace(Uri.parse(
          'http://localhost:5000/?error=access_denied&error_code=otp_expired'));
      expect(mensaje, contains('venció o ya se usó'));
    });

    test('sin error no muestra nada', () {
      expect(
        Recuperacion.errorDelEnlace(Uri.parse('http://localhost:5000/')),
        isNull,
      );
    });
  });
}
