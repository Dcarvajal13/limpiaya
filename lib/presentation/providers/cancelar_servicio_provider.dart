import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/servicio_service.dart';

/// HU-28 · Cancelar un servicio asignado (cliente o trabajadora).
///
/// `cancelar()` devuelve `null` si se canceló, o el mensaje que debe ver
/// quien canceló si falló. No es `autoDispose` por la misma razón que
/// `elegirTrabajadoraProvider`: se usa con `ref.read(...)` tras un diálogo.
final cancelarServicioProvider =
    NotifierProvider<CancelarServicioNotifier, AsyncValue<void>>(
  CancelarServicioNotifier.new,
);

class CancelarServicioNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> cancelar(String solicitudId, {required String motivo}) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref
          .read(servicioRepositoryProvider)
          .cancelar(solicitudId, motivo: motivo),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : ServicioService.mensajeErrorCancelar;
    }
    return null;
  }
}
