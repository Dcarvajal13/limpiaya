import '../entities/estado_solicitud.dart';

/// Reglas del chat que no dependen de la base de datos (HU-38).
///
/// La base también las revisa (`chat_abierto()` en la migración de seguridad
/// y el `check` de 500 caracteres en `mensajes`), pero validarlas antes deja
/// mensajes claros y evita viajes que van a fallar.
abstract final class ChatService {
  /// Lo mismo que acepta la columna `contenido` de `mensajes`.
  static const maxCaracteres = 500;

  /// Un chat sigue abierto mientras el servicio está Asignado y, una vez
  /// terminado o cancelado, durante los 7 días siguientes.
  ///
  /// Es la misma regla que `public.chat_abierto()`.
  static const diasChatAbierto = 7;

  static const mensajeVacio = 'Escribe un mensaje antes de enviarlo.';
  static const mensajeLargo =
      'El mensaje no puede pasar de $maxCaracteres caracteres.';
  static const mensajeCerrado =
      'El chat de este servicio ya está cerrado.';
  static const mensajeError = 'No pudimos enviar tu mensaje. Intenta de nuevo.';
  static const mensajeSinAcceso = 'No tienes acceso a este chat.';

  /// Devuelve el error que debe ver la persona, o null si se puede enviar.
  static String? validar(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return mensajeVacio;
    if (limpio.length > maxCaracteres) return mensajeLargo;
    return null;
  }

  /// Si se pueden enviar mensajes nuevos en este servicio.
  static bool chatAbierto(
    EstadoSolicitud estado, {
    DateTime? completadaEn,
    DateTime? canceladaEn,
    DateTime? ahora,
  }) {
    if (estado == EstadoSolicitud.asignada) return true;
    if (estado == EstadoSolicitud.publicada) return false;

    final cierre = estado == EstadoSolicitud.completada
        ? completadaEn
        : canceladaEn;
    if (cierre == null) return false;

    final momento = ahora ?? DateTime.now();
    return momento.difference(cierre) < const Duration(days: diasChatAbierto);
  }
}
