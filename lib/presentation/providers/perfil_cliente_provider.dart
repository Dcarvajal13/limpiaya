import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/perfil_cliente.dart';
import '../../domain/entities/zona.dart';
import 'sesion_provider.dart';

/// Perfil del cliente que inició sesión (HU-05).
final perfilClienteProvider =
    AsyncNotifierProvider<PerfilClienteController, PerfilCliente?>(
        PerfilClienteController.new);

/// Catálogo de zonas de Caracas, para el selector del formulario.
final zonasClienteProvider = FutureProvider<List<Zona>>((ref) async {
  return ref.read(clienteRepositoryProvider).zonasDisponibles();
});

/// Estado del perfil del cliente: cargar y guardar.
class PerfilClienteController extends AsyncNotifier<PerfilCliente?> {
  @override
  Future<PerfilCliente?> build() =>
      ref.read(clienteRepositoryProvider).miPerfil();

  /// Guarda el perfil y lo vuelve a leer. Devuelve true si salió bien.
  Future<bool> guardar({
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clienteRepositoryProvider).guardarPerfil(
            zonaId: zonaId,
            direccion: direccion,
            puntoReferencia: puntoReferencia,
          );
      // La sesión sabe si el perfil está completo (HU-02A, criterio 4).
      ref.invalidate(sesionProvider);
      return ref.read(clienteRepositoryProvider).miPerfil();
    });
    return !state.hasError;
  }
}
