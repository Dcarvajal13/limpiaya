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

  /// "17 oct." (pestaña Postulaciones, Figma W07).
  static String diaMesCorto(DateTime fecha) =>
      '${fecha.day} ${_meses[fecha.month - 1]}.';

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

  static const _diasCompletos = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
  static const _mesesCompletos = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "Sábado, 9:00 a. m." (tarjeta del cliente, Figma C05).
  static String diaCompletoHora(DateTime fecha) =>
      '${_diasCompletos[fecha.weekday - 1]}, ${hora(fecha)}';

  /// "Sábado", "Martes", etc.
  static String diaDeSemana(DateTime fecha) =>
      _diasCompletos[fecha.weekday - 1];

  /// "OCT" (tarjeta del cliente, cuadro de fecha).
  static String mesMayus(DateTime fecha) =>
      _meses[fecha.month - 1].toUpperCase();

  /// "17 de octubre"
  static String diaDeMes(DateTime fecha) =>
      '${fecha.day} de ${_mesesCompletos[fecha.month - 1]}';

  /// "Sábado 24 de octubre" (Mis servicios, Figma W07).
  static String fechaLarga(DateTime fecha) =>
      '${diaDeSemana(fecha)} ${diaDeMes(fecha)}';

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

  /// "2 de octubre de 2026" (cuenta creada, panel del admin, HU-33).
  static String fechaConAnio(DateTime fecha) =>
      '${diaDeMes(fecha)} de ${fecha.year}';

  /// "4 oct. · 9:20 a. m." (lista de verificaciones del admin, HU-33).
  static String fechaHoraCorta(DateTime fecha) =>
      '${fecha.day} ${_meses[fecha.month - 1]}. · ${hora(fecha)}';
}
