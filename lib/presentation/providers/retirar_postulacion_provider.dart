import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/postulacion_service.dart';

/// HU-26 · Retirar una postulación pendiente.
///
/// `retirar()` devuelve `null` si se retiró, o el mensaje que debe ver la
/// trabajadora si falló (ya la aceptaron, sin red…). La pantalla decide qué
/// refrescar cuando el resultado es `null`.
/// No es `autoDispose` a propósito, igual que `postularSolicitudProvider`: el
/// retiro se hace con `ref.read(...)` desde un diálogo y un provider
/// autoDispose sin listeners se destruye a mitad del `await`.
final retirarPostulacionProvider =
    NotifierProvider<RetirarPostulacionNotifier, AsyncValue<void>>(
  RetirarPostulacionNotifier.new,
);

class RetirarPostulacionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> retirar(String postulacionId) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(postulacionRepositoryProvider).retirar(postulacionId),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : PostulacionService.mensajeErrorRetirar;
    }
    return null;
  }
}
