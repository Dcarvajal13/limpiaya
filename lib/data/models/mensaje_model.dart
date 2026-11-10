import '../../domain/entities/mensaje.dart';

/// Conversión de una fila de `mensajes` a la entidad del chat (HU-38).
abstract final class MensajeModel {
  static Mensaje desdeJson(Map<String, dynamic> json) {
    return Mensaje(
      id: (json['id'] as num).toInt(),
      solicitudId: json['solicitud_id'] as String,
      autorId: json['autor_id'] as String,
      contenido: json['contenido'] as String,
      enviadoEn: DateTime.parse(json['created_at'] as String).toLocal(),
      leidoEn: json['leido_en'] != null
          ? DateTime.parse(json['leido_en'] as String).toLocal()
          : null,
    );
  }
}
