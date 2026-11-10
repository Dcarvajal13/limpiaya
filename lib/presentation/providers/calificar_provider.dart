import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/calificacion_service.dart';

/// HU-29 · Enviar una calificación.
///
/// `calificar()` devuelve `null` si se guardó, o el mensaje que debe ver
/// quien califica si falló. No es `autoDispose` por la misma razón que
/// `elegirTrabajadoraProvider`: se usa con `ref.read(...)` tras un diálogo.
final calificarProvider =
    NotifierProvider<CalificarNotifier, AsyncValue<void>>(
  CalificarNotifier.new,
);

class CalificarNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> calificar({
    required String solicitudId,
    required String destinatarioId,
    required int estrellas,
    String? comentario,
  }) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(calificacionRepositoryProvider).calificar(
            solicitudId: solicitudId,
            destinatarioId: destinatarioId,
            estrellas: estrellas,
            comentario: comentario,
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : CalificacionService.mensajeError;
    }
    return null;
  }
}
