import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';

/// E9 · Cobrar un servicio sin mover dinero de verdad.
///
/// El pago se guarda en la base (`pagar_servicio`): un solo toque en el botón
/// basta, sin formulario ni datos de tarjeta. La espera de [espera] solo
/// existe para que la pantalla alcance a mostrar el "procesando".
final pagarServicioProvider =
    NotifierProvider<PagarServicioNotifier, AsyncValue<void>>(
  PagarServicioNotifier.new,
);

class PagarServicioNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  static const espera = Duration(milliseconds: 900);

  static const mensajeError = 'No pudimos registrar el pago. Intenta de nuevo.';

  /// Devuelve `null` si el pago quedó guardado, o el mensaje para el cliente.
  Future<String?> pagar(String solicitudId) async {
    state = const AsyncLoading();
    await Future<void>.delayed(espera);

    final resultado = await AsyncValue.guard(
      () => ref.read(pagoRepositoryProvider).pagar(solicitudId),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException ? error.mensaje : mensajeError;
    }
    return null;
  }
}
