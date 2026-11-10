import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/servicio_service.dart';

/// HU-17 · Marcar un servicio como completado.
///
/// `completar()` devuelve `null` si se completó, o el mensaje que debe ver
/// el cliente si falló. No es `autoDispose` por la misma razón que
/// `elegirTrabajadoraProvider`: se usa con `ref.read(...)` tras un diálogo.
final completarServicioProvider =
    NotifierProvider<CompletarServicioNotifier, AsyncValue<void>>(
  CompletarServicioNotifier.new,
);

class CompletarServicioNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> completar(String solicitudId) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(servicioRepositoryProvider).completar(solicitudId),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : ServicioService.mensajeErrorCompletar;
    }
    return null;
  }
}
