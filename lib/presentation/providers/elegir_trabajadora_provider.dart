import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/servicio_service.dart';

/// HU-15 · Elegir a una trabajadora.
///
/// `elegir()` devuelve `null` si se eligió, o el mensaje que debe ver el
/// cliente si falló. La pantalla decide qué refrescar cuando sale bien.
/// No es `autoDispose` a propósito, igual que `retirarPostulacionProvider`:
/// se usa con `ref.read(...)` después de un diálogo, y un provider autoDispose
/// sin listeners se destruye a mitad del `await`.
final elegirTrabajadoraProvider =
    NotifierProvider<ElegirTrabajadoraNotifier, AsyncValue<void>>(
  ElegirTrabajadoraNotifier.new,
);

class ElegirTrabajadoraNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> elegir(String postulacionId) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(servicioRepositoryProvider).elegir(postulacionId),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException
          ? error.mensaje
          : ServicioService.mensajeErrorElegir;
    }
    return null;
  }
}
