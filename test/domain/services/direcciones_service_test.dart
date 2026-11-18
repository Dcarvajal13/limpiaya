import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/direccion_guardada.dart';
import 'package:limpiaya/domain/services/direcciones_service.dart';

DireccionGuardada _d(
  String id,
  String nombre, {
  int zona = 1,
  String direccion = 'Av. Principal, Edificio Sol',
}) =>
    DireccionGuardada(
      id: id,
      nombre: nombre,
      zonaId: zona,
      direccion: direccion,
    );

void main() {
  group('validarNombre', () {
    final mias = [_d('1', 'Casa'), _d('2', 'Trabajo')];

    test('pide un nombre', () {
      expect(DireccionesService.validarNombre('  ', mias), isNotNull);
    });

    test('no repite nombres (sin importar mayúsculas)', () {
      expect(
        DireccionesService.validarNombre(' casa ', mias),
        DireccionesService.nombreRepetido,
      );
    });

    test('al editar puede quedarse con su propio nombre', () {
      expect(DireccionesService.validarNombre('Casa', mias, id: '1'), isNull);
    });

    test('máximo 40 caracteres', () {
      expect(DireccionesService.validarNombre('a' * 41, mias), isNotNull);
    });
  });

  test('coincidencia: reconoce la dirección guardada que está escrita', () {
    final mias = [_d('1', 'Casa', direccion: 'Av. Principal, Edificio Sol')];
    expect(
      DireccionesService.coincidencia(
        mias,
        zonaId: 1,
        direccion: '  av. principal,   edificio sol ',
      )?.id,
      '1',
    );
    expect(
      DireccionesService.coincidencia(
        mias,
        zonaId: 2,
        direccion: 'Av. Principal, Edificio Sol',
      ),
      isNull,
    );
  });

  test('nombreSugerido: Casa, luego Trabajo, luego Casa de mis padres', () {
    expect(DireccionesService.nombreSugerido(const []), 'Casa');
    expect(DireccionesService.nombreSugerido([_d('1', 'Casa')]), 'Trabajo');
    expect(
      DireccionesService.nombreSugerido(
        [_d('1', 'Casa'), _d('2', 'Trabajo'), _d('3', 'Casa de mis padres')],
      ),
      'Dirección 4',
    );
  });

  test('máximo 10 direcciones', () {
    final nueve = [for (var i = 0; i < 9; i++) _d('$i', 'D$i')];
    expect(DireccionesService.puedeAgregar(nueve), isTrue);
    expect(DireccionesService.puedeAgregar([...nueve, _d('x', 'X')]), isFalse);
  });

  test('traduce el nombre repetido de la base', () {
    expect(
      DireccionesService.traducir(
        'duplicate key value violates unique constraint '
        '"direcciones_cliente_nombre_idx"',
      ),
      DireccionesService.nombreRepetido,
    );
    expect(DireccionesService.traducir('otra cosa'),
        DireccionesService.errorGuardar);
  });
}
