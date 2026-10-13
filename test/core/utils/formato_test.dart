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

  test('hora: 12 h, mediodía y tarde', () {
    expect(Formato.hora(DateTime(2026, 10, 21, 14)), '2:00 p. m.');
    expect(Formato.hora(DateTime(2026, 10, 21, 12)), '12:00 p. m.');
    expect(Formato.hora(DateTime(2026, 10, 21, 0, 30)), '12:30 a. m.');
  });

  test('horas: singular y decimales', () {
    expect(Formato.horas(1), '1 hora');
    expect(Formato.horas(4.5), '4,5 horas');
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
}
