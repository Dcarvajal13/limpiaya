/// Formatos de texto en español para las tarjetas (sin depender de `intl`).
abstract final class Formato {
  static const _dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  /// 30 → "$30", 28.5 → "$28.50".
  static String dinero(double monto) {
    final entero = monto == monto.roundToDouble();
    return '\$${entero ? monto.toStringAsFixed(0) : monto.toStringAsFixed(2)}';
  }

  /// "Sáb 17 oct"
  static String diaCorto(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]} ${fecha.day} ${_meses[fecha.month - 1]}';

  /// "8:00 a. m." / "2:00 p. m."
  static String hora(DateTime fecha) {
    final h12 = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    final minutos = fecha.minute.toString().padLeft(2, '0');
    final sufijo = fecha.hour < 12 ? 'a. m.' : 'p. m.';
    return '$h12:$minutos $sufijo';
  }

  /// 1 → "1 hora", 5 → "5 horas", 4.5 → "4,5 horas".
  static String horas(double horas) {
    final entero = horas == horas.roundToDouble();
    final texto = entero
        ? horas.toStringAsFixed(0)
        : horas.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto ${horas == 1 ? 'hora' : 'horas'}';
  }

  /// 0 → "0 postulantes", 1 → "1 postulante".
  static String postulantes(int cantidad) =>
      '$cantidad ${cantidad == 1 ? 'postulante' : 'postulantes'}';

  /// "Sáb 17 oct · 8:00 a. m. · 5 horas"
  static String horario(DateTime inicio, double horasEstimadas) =>
      '${diaCorto(inicio)} · ${hora(inicio)} · ${horas(horasEstimadas)}';

  /// "Sáb. 17 oct." (tarjeta de solicitud, Figma W06).
  static String diaTarjeta(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]}. ${fecha.day} ${_meses[fecha.month - 1]}.';

  /// "17/10/2026" (campo "Desde la fecha").
  static String fechaNumerica(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  /// 3 → "3 hab."
  static String habitaciones(int cantidad) => '$cantidad hab.';

  /// 1 → "1 baño", 2 → "2 baños".
  static String banos(int cantidad) =>
      '$cantidad ${cantidad == 1 ? 'baño' : 'baños'}';

  /// 4.9 → "4,9" (promedio de estrellas).
  static String promedio(double valor) =>
      valor.toStringAsFixed(1).replaceAll('.', ',');

  /// "Buenos días" / "Buenas tardes" / "Buenas noches" según la hora.
  static String saludo(DateTime ahora) {
    if (ahora.hour < 12) return 'Buenos días';
    if (ahora.hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  /// ["A"] → "A", ["A", "B"] → "A y B", ["A", "B", "C"] → "A, B y C".
  static String lista(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
  }
}
