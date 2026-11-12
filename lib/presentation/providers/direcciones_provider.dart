import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/direccion_guardada.dart';
import '../../domain/services/direcciones_service.dart';

/// Direcciones guardadas del cliente que inició sesión.
final misDireccionesProvider = FutureProvider<List<DireccionGuardada>>(
  (ref) => ref.watch(direccionesRepositoryProvider).misDirecciones(),
  retry: (intentos, error) => null,
);

/// Guardar y eliminar direcciones.
///
/// Cada acción devuelve `null` si salió bien, o el mensaje que debe ver el
/// cliente. No es `autoDispose` porque se usa con `ref.read(...)` desde
/// diálogos (igual que `invitarTrabajadoraProvider`).
final direccionesProvider =
    NotifierProvider<DireccionesController, AsyncValue<void>>(
  DireccionesController.new,
);

class DireccionesController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<String?> guardar({
    String? id,
    required String nombre,
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) =>
      _hacer(
        () => ref.read(direccionesRepositoryProvider).guardar(
              id: id,
              nombre: nombre,
              zonaId: zonaId,
              direccion: direccion,
              puntoReferencia: puntoReferencia,
            ),
        DireccionesService.errorGuardar,
      );

  Future<String?> eliminar(String id) => _hacer(
        () => ref.read(direccionesRepositoryProvider).eliminar(id),
        DireccionesService.errorEliminar,
      );

  Future<String?> _hacer(
    Future<void> Function() accion,
    String mensajeGenerico,
  ) async {
    state = const AsyncLoading();
    final resultado = await AsyncValue.guard(accion);
    state = resultado;
    if (resultado.hasError) {
      final error = resultado.error;
      return error is AppException ? error.mensaje : mensajeGenerico;
    }
    ref.invalidate(misDireccionesProvider);
    return null;
  }
}
