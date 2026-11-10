import '../entities/conversacion.dart';
import '../entities/mensaje.dart';

/// Contrato del chat entre las dos partes de un servicio (HU-38).
///
/// La implementación con Supabase está en
/// data/repositories/supabase_chat_repository.dart. Las reglas de quién
/// puede leer y escribir las pone la base (RLS y `chat_abierto()`): aquí solo
/// se piden las cosas.
abstract interface class ChatRepository {
  /// HU-38 c3 · Conversaciones de mis servicios con su último mensaje y
  /// cuántos mensajes de la otra parte siguen sin leer.
  ///
  /// Solo vienen las que ya tienen algún mensaje.
  Future<List<Conversacion>> conversaciones();

  /// HU-38 c2 · Mensajes del servicio, del más viejo al más nuevo, y los
  /// nuevos en cuanto llegan (Realtime).
  Stream<List<Mensaje>> mensajes(String solicitudId);

  /// Envía un mensaje como la persona con sesión. Lanza `AppException` con
  /// un mensaje claro si el chat se cerró o si no es parte del servicio.
  Future<void> enviar(String solicitudId, String contenido);

  /// Marca como leídos los mensajes que escribió la otra parte.
  Future<void> marcarLeidos(String solicitudId);
}
