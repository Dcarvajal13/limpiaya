import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/utils/formato.dart';

void main() {
  test('dinero: sin decimales si es entero', () {
    expect(Formato.dinero(30), r'$30');
    expect(Formato.dinero(28.5), r'$28.50');
  });

  test('horario: igual al Figma', () {
    // Sábado 17 de octubre de 2026, 8:00 a. m.
    final inicio = DateTime(2026, 10, 17, 8);
    expect(Formato.horario(inicio, 5), 'Sáb 17 oct · 8:00 a. m. · 5 horas');
  });

  test('tarjeta W06: día, casa, fecha numérica y promedio', () {
    expect(Formato.diaTarjeta(DateTime(2026, 10, 17, 9)), 'Sáb. 17 oct.');
    expect(Formato.fechaNumerica(DateTime(2026, 3, 7)), '07/03/2026');
    expect(Formato.habitaciones(3), '3 hab.');
    expect(Formato.banos(1), '1 baño');
    expect(Formato.banos(2), '2 baños');
    expect(Formato.promedio(4.9), '4,9');
    expect(Formato.promedio(5), '5,0');
  });

  test('hora: 12 h, mediodía y tarde', () {
    expect(Formato.hora(DateTime(2026, 10, 21, 14)), '2:00 p. m.');
    expect(Formato.hora(DateTime(2026, 10, 21, 12)), '12:00 p. m.');
    expect(Formato.hora(DateTime(2026, 10, 21, 0, 30)), '12:30 a. m.');
  });

  test('horas: singular y decimales', () {
    expect(Formato.horas(1), '1 hora');
    expect(Formato.horas(4.5), '4,5 horas');
  });

  test('fechaLarga: igual al Figma de Mis servicios', () {
    expect(
      Formato.fechaLarga(DateTime(2026, 10, 24, 8, 30)),
      'Sábado 24 de octubre',
    );
  });

  test('postulantes: singular y plural', () {
    expect(Formato.postulantes(0), '0 postulantes');
    expect(Formato.postulantes(1), '1 postulante');
    expect(Formato.postulantes(3), '3 postulantes');
  });

  test('saludo según la hora', () {
    expect(Formato.saludo(DateTime(2026, 10, 12, 8)), 'Buenos días');
    expect(Formato.saludo(DateTime(2026, 10, 12, 15)), 'Buenas tardes');
    expect(Formato.saludo(DateTime(2026, 10, 12, 21)), 'Buenas noches');
  });

  test('lista: une con comas y "y"', () {
    expect(Formato.lista(['A']), 'A');
    expect(Formato.lista(['A', 'B']), 'A y B');
    expect(Formato.lista(['A', 'B', 'C']), 'A, B y C');
  });

  test('HU-33: fecha con año y fecha con hora de la lista del admin', () {
    expect(Formato.fechaConAnio(DateTime(2026, 10, 2)), '2 de octubre de 2026');
    expect(
      Formato.fechaHoraCorta(DateTime(2026, 10, 4, 9, 20)),
      '4 oct. · 9:20 a. m.',
    );
  });
}
