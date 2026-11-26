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

  /// HU-48 · Reemplazo para datos de contacto detectados en el chat.
  static const etiquetaContactoOculto = '[contacto oculto]';
  static const avisoContactoOculto =
      'Por seguridad, ocultamos teléfonos, correos y enlaces externos en el chat.';

  static final _patronEnlaceContacto = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:wa\.me|api\.whatsapp\.com|whatsapp\.com|t\.me)\/[^\s]*|'
    r'\b(?:wa\.me|whatsapp\.com|t\.me)\b',
    caseSensitive: false,
  );

  static final _patronCorreo = RegExp(
    r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b',
  );

  // Secuencias numéricas con separadores típicos de teléfono (+58 414-1234567,
  // 0412 555 0101, (0212) 555-1234). Se filtra a >= 7 dígitos reales para no
  // afectar horas, precios ni números de apartamento.
  static final _patronTelefono = RegExp(
    r'(?<!\w)(?:\+?\d[\d\s().-]{6,}\d)(?!\w)',
  );

  /// HU-48 · Indica si [texto] contiene teléfonos, correos o enlaces `wa.me`.
  static bool contieneContacto(String texto) {
    if (_patronEnlaceContacto.hasMatch(texto)) return true;
    if (_patronCorreo.hasMatch(texto)) return true;
    for (final m in _patronTelefono.allMatches(texto)) {
      final digitos = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digitos.length >= 7) return true;
    }
    return false;
  }

  /// HU-48 · Oculta teléfonos, correos y enlaces `wa.me` reemplazándolos por
  /// [etiquetaContactoOculto].
  static String ocultarContactos(String texto) {
    var resultado = texto.replaceAll(_patronEnlaceContacto, etiquetaContactoOculto);
    resultado = resultado.replaceAll(_patronCorreo, etiquetaContactoOculto);
    resultado = resultado.replaceAllMapped(_patronTelefono, (m) {
      final segmento = m.group(0)!;
      final digitos = segmento.replaceAll(RegExp(r'\D'), '');
      return digitos.length >= 7 ? etiquetaContactoOculto : segmento;
    });
    return resultado;
  }

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
