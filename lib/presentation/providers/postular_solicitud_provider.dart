import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/postulacion_service.dart';

/// HU-12 · Enviar una postulación a una solicitud publicada.
///
/// `postular()` devuelve `null` si se envió, o el mensaje que debe ver la
/// trabajadora si falló (ya postulada, choque de horario, sin red…).
/// Las pantallas deciden qué refrescar cuando el resultado es `null`.
/// No es `autoDispose` a propósito: el envío se hace con `ref.read(...)` desde
/// un diálogo, y un provider autoDispose sin listeners se destruye a mitad del
/// `await` (UnmountedRefException).
final postularSolicitudProvider =
    NotifierProvider<PostularSolicitudNotifier, AsyncValue<void>>(
  PostularSolicitudNotifier.new,
);

class PostularSolicitudNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> postular({
    required String solicitudId,
    String? mensaje,
  }) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(postulacionRepositoryProvider).postular(
            solicitudId: solicitudId,
            mensaje: mensaje,
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : PostulacionService.mensajeError;
    }
    return null;
  }
}
