import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/mi_reputacion.dart';
import '../../domain/services/respuesta_service.dart';

/// HU-31 · Mi promedio y las reseñas que me dejaron, con mis respuestas.
final miReputacionProvider = FutureProvider.autoDispose<MiReputacion>(
  (ref) => ref.watch(miReputacionRepositoryProvider).miReputacion(),
  retry: (intentos, error) => null,
);

/// HU-31 · Publicar o editar la respuesta a una reseña.
///
/// `responder()` devuelve `null` si se guardó, o el mensaje que debe ver la
/// trabajadora si falló. No es `autoDispose` por la misma razón que
/// `calificarProvider`: se usa con `ref.read(...)` tras un diálogo.
final responderResenaProvider =
    NotifierProvider<ResponderResenaNotifier, AsyncValue<void>>(
  ResponderResenaNotifier.new,
);

class ResponderResenaNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> responder({
    required String calificacionId,
    required String texto,
  }) async {
    // c3 · Se valida antes de ir a la base.
    final invalida = RespuestaService.validar(texto);
    if (invalida != null) return invalida;

    state = const AsyncLoading();
    final resultado = await AsyncValue.guard(
      () => ref.read(miReputacionRepositoryProvider).responder(
            calificacionId: calificacionId,
            texto: texto.trim(),
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException ? error.mensaje : RespuestaService.mensajeError;
    }
    return null;
  }
}
