import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/router/recuperacion.dart';
import 'package:limpiaya/core/router/verificacion_correo.dart';

void main() {
  group('HU-40 · estado del enlace', () {
    test('sin la marca no viene del enlace', () {
      expect(
        VerificacionCorreo.estado(Uri.parse('http://localhost:5000/')),
        EstadoEnlaceCorreo.ninguno,
      );
      expect(
        VerificacionCorreo.estado(
          Uri.parse('http://localhost:5000/?recuperar=1&code=abc'),
        ),
        EstadoEnlaceCorreo.ninguno,
      );
    });

    test('c1 · con la marca y el código, quedó verificado', () {
      expect(
        VerificacionCorreo.estado(
          Uri.parse('http://localhost:5000/?verificado=1&code=abc'),
        ),
        EstadoEnlaceCorreo.verificado,
      );
    });

    test('c3 · si el enlace ya se usó (otp_expired), "ya está verificado"', () {
      expect(
        VerificacionCorreo.estado(
          Uri.parse(
            'http://localhost:5000/?verificado=1&error=access_denied'
            '&error_code=otp_expired&error_description=Email+link+is+invalid',
          ),
        ),
        EstadoEnlaceCorreo.yaUsado,
      );
    });

    test('c3 · también si el error viene después del #', () {
      expect(
        VerificacionCorreo.estado(
          Uri.parse(
            'http://localhost:5000/?verificado=1#error=access_denied'
            '&error_code=otp_expired',
          ),
        ),
        EstadoEnlaceCorreo.yaUsado,
      );
    });

    test('otro error del enlace', () {
      expect(
        VerificacionCorreo.estado(
          Uri.parse('http://localhost:5000/?verificado=1&error_code=bad_jwt'),
        ),
        EstadoEnlaceCorreo.error,
      );
    });
  });

  test('el enlace de regreso es la raíz de la app con ?verificado=1', () {
    expect(
      VerificacionCorreo.enlaceDeRegreso(
        Uri.parse('http://localhost:51884/#/registro'),
      ),
      'http://localhost:51884/?verificado=1',
    );
    expect(
      VerificacionCorreo.enlaceDeRegreso(
        Uri.parse('https://limpiaya.app/#/registro'),
      ),
      'https://limpiaya.app/?verificado=1',
    );
  });

  test('el login no muestra el error de HU-19 por un enlace de HU-40', () {
    expect(
      Recuperacion.errorDelEnlace(
        Uri.parse('http://localhost:5000/?verificado=1&error_code=otp_expired'),
      ),
      isNull,
    );
  });
}
