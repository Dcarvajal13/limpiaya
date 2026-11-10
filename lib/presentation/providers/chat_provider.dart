import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/services/chat_service.dart';
import 'sesion_provider.dart';

/// HU-38 c3 · Conversaciones de mis servicios con su último mensaje y sus
/// mensajes sin leer.
final conversacionesProvider =
    FutureProvider.autoDispose<List<Conversacion>>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(chatRepositoryProvider).conversaciones();
  },
  retry: (intentos, error) => null,
);

/// Cuántos mensajes de la otra parte siguen sin leer, para el aviso de la
/// pestaña "Mensajes".
final noLeidosProvider = Provider.autoDispose<int>((ref) {
  final conversaciones = ref.watch(conversacionesProvider).value;
  if (conversaciones == null) return 0;
  return conversaciones.fold<int>(0, (total, c) => total + c.noLeidos);
});

/// HU-38 c2 · Mensajes de un servicio, con los nuevos en vivo.
final mensajesProvider =
    StreamProvider.autoDispose.family<List<Mensaje>, String>(
  (ref, solicitudId) => ref.watch(chatRepositoryProvider).mensajes(solicitudId),
  retry: (intentos, error) => null,
);

/// Enviar un mensaje: valida antes de salir y devuelve el error a mostrar,
/// o null si se envió.
final enviarMensajeProvider =
    NotifierProvider<EnviarMensajeNotifier, AsyncValue<void>>(
  EnviarMensajeNotifier.new,
);

class EnviarMensajeNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> enviar(String solicitudId, String texto) async {
    // Las mismas reglas que el `check` de la base, para no ir y volver.
    final error = ChatService.validar(texto);
    if (error != null) return error;

    state = const AsyncLoading();
    final resultado = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).enviar(solicitudId, texto.trim()),
    );
    state = resultado;

    if (resultado.hasError) {
      final fallo = resultado.error;
      return fallo is AppException ? fallo.mensaje : ChatService.mensajeError;
    }
    // El último mensaje y el aviso de no leídos cambian con cada envío.
    ref.invalidate(conversacionesProvider);
    return null;
  }
}
