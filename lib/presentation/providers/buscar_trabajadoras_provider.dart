import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_publico.dart';
import '../../domain/services/busqueda_service.dart';

/// HU-25 c1 · Trabajadoras verificadas, filtradas por zona (`null` = todas).
/// El orden (c2) lo aplica la pantalla con BusquedaService.ordenar.
final buscarTrabajadorasProvider =
    FutureProvider.autoDispose.family<List<PerfilPublico>, int?>(
  (ref, zonaId) =>
      ref.watch(busquedaTrabajadorasRepositoryProvider).buscar(zonaId: zonaId),
  retry: (intentos, error) => null,
);

/// Mis invitaciones (a quién invité y en qué solicitud), para mostrar
/// "Invitada" en la tarjeta de cada trabajadora.
final misInvitacionesProvider = FutureProvider.autoDispose<
    List<({String solicitudId, String trabajadoraId})>>(
  (ref) => ref.watch(busquedaTrabajadorasRepositoryProvider).misInvitaciones(),
  retry: (intentos, error) => null,
);

/// HU-25 c3 · Invitar a una trabajadora a una solicitud.
///
/// `invitar()` devuelve `null` si se envió, o el mensaje que debe ver el
/// cliente. No es `autoDispose` porque se usa con `ref.read(...)` desde un
/// diálogo (igual que `calificarProvider`).
final invitarTrabajadoraProvider =
    NotifierProvider<InvitarTrabajadoraNotifier, AsyncValue<void>>(
  InvitarTrabajadoraNotifier.new,
);

class InvitarTrabajadoraNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> invitar({
    required String solicitudId,
    required String trabajadoraId,
  }) async {
    state = const AsyncLoading();
    final resultado = await AsyncValue.guard(
      () => ref.read(busquedaTrabajadorasRepositoryProvider).invitar(
            solicitudId: solicitudId,
            trabajadoraId: trabajadoraId,
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException ? error.mensaje : BusquedaService.errorInvitar;
    }
    // La tarjeta de la trabajadora pasa a decir "Invitada".
    ref.invalidate(misInvitacionesProvider);
    return null;
  }
}
