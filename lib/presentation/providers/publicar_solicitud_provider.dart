import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/direccion_cliente.dart';
import '../../domain/entities/nueva_solicitud.dart';
import '../../domain/entities/solicitud.dart';
import '../../domain/entities/zona.dart';

import 'mis_solicitudes_provider.dart';

/// Catálogo de zonas de Caracas para el selector (reutiliza HU-04).
final zonasCatalogoProvider = FutureProvider<List<Zona>>(
  (ref) => ref.watch(perfilRepositoryProvider).zonasDisponibles(),
);

/// Zona y dirección guardadas del cliente, para precargar el formulario.
final direccionGuardadaProvider = FutureProvider<DireccionCliente?>(
  (ref) => ref.watch(solicitudRepositoryProvider).miDireccion(),
);

/// HU-09 · La solicitud que se va a editar, con su dirección.
final solicitudParaEditarProvider =
    FutureProvider.autoDispose.family<Solicitud?, String>(
  (ref, id) => ref.watch(solicitudRepositoryProvider).miSolicitud(id),
  retry: (intentos, error) => null,
);

/// Controlador de la pantalla Publicar solicitud (HU-07) y de su versión
/// para editar (HU-09).
final publicarSolicitudProvider =
    NotifierProvider<PublicarSolicitudController, AsyncValue<void>>(
  PublicarSolicitudController.new,
);

class PublicarSolicitudController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Devuelve true si la solicitud se publicó.
  Future<bool> publicar(NuevaSolicitud solicitud) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<void>(() async {
      await ref.read(solicitudServiceProvider).publicar(solicitud);
      ref.invalidate(misSolicitudesProvider);
    });
    return !state.hasError;
  }

  /// HU-09 · Devuelve true si los cambios se guardaron.
  Future<bool> editar(Solicitud original, NuevaSolicitud cambios) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard<void>(() async {
      await ref.read(solicitudServiceProvider).editar(original, cambios);
      ref.invalidate(misSolicitudesProvider);
    });
    return !state.hasError;
  }
}
