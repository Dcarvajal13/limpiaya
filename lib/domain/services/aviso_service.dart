import '../entities/aviso.dart';
import '../entities/correo_aviso.dart';

/// Reglas puras de dominio para HU-50 (campana) y HU-49 (avisos por correo).
abstract final class AvisoService {
  /// Cantidad de avisos sin leer para el contador de la campana (HU-50).
  static int contarNoLeidos(List<Aviso> avisos) =>
      avisos.where((a) => !a.leido).length;

  /// Texto compacto para el badge de la campana (`99+` si supera 99).
  static String etiquetaContador(int cantidad) {
    if (cantidad <= 0) return '';
    return cantidad > 99 ? '99+' : '$cantidad';
  }

  /// Calcula la fecha de envío del recordatorio de 24 horas (HU-49).
  /// Devuelve null si el servicio empieza en menos de 24 horas.
  static DateTime? fechaRecordatorio24h(DateTime inicio, {DateTime? ahora}) {
    final referencia = ahora ?? DateTime.now();
    final recordatorio = inicio.subtract(const Duration(hours: 24));
    return recordatorio.isAfter(referencia) ? recordatorio : null;
  }

  /// Asunto estándar por tipo de evento de correo (HU-49).
  static String asuntoPara(TipoCorreoAviso tipo) => switch (tipo) {
        TipoCorreoAviso.postulacion =>
          'Nueva postulación en tu solicitud · LimpiaYa',
        TipoCorreoAviso.eleccion =>
          '¡Te eligieron para un servicio! · LimpiaYa',
        TipoCorreoAviso.recordatorio24h =>
          'Recordatorio: tu servicio es en 24 horas · LimpiaYa',
        TipoCorreoAviso.cancelacion => 'Servicio cancelado · LimpiaYa',
      };
}
