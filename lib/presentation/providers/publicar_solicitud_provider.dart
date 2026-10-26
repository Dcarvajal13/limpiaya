import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/direccion_cliente.dart';
import '../../domain/entities/nueva_solicitud.dart';
import '../../domain/entities/zona.dart';

/// Catálogo de zonas de Caracas para el selector (reutiliza HU-04).
final zonasCatalogoProvider = FutureProvider<List<Zona>>(
  (ref) => ref.watch(perfilRepositoryProvider).zonasDisponibles(),
);

/// Zona y dirección guardadas del cliente, para precargar el formulario.
final direccionGuardadaProvider = FutureProvider<DireccionCliente?>(
  (ref) => ref.watch(solicitudRepositoryProvider).miDireccion(),
);

/// Controlador de la pantalla Publicar solicitud (HU-07).
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
    });
    return !state.hasError;
  }
}