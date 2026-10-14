import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/perfil_trabajadora.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';
import 'sesion_provider.dart';

/// Perfil de la trabajadora que inició sesión (HU-04).
final perfilProvider =
    AsyncNotifierProvider<PerfilController, PerfilTrabajadora?>(PerfilController.new);

/// Catálogo de zonas de Caracas, para los chips del formulario.
final zonasProvider = FutureProvider<List<Zona>>((ref) async {
  return ref.read(perfilRepositoryProvider).zonasDisponibles();
});

/// Estado del perfil: cargar, guardar y subir la foto.
class PerfilController extends AsyncNotifier<PerfilTrabajadora?> {
  @override
  Future<PerfilTrabajadora?> build() => ref.read(perfilRepositoryProvider).miPerfil();

  /// Guarda el perfil y lo vuelve a leer. Devuelve true si salió bien.
  Future<bool> guardar({
    required List<int> zonasIds,
    required List<TipoLimpieza> servicios,
    int? experienciaAnios,
    double? tarifaReferencia,
    String? descripcion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(perfilRepositoryProvider).guardarPerfil(
            zonasIds: zonasIds,
            servicios: servicios,
            experienciaAnios: experienciaAnios,
            tarifaReferencia: tarifaReferencia,
            descripcion: descripcion,
          );
      // La sesión sabe si el perfil está completo: hay que refrescarla para
      // que el router deje entrar a las solicitudes (HU-04, criterio 1).
      ref.invalidate(sesionProvider);
      return ref.read(perfilRepositoryProvider).miPerfil();
    });
    return !state.hasError;
  }

  /// Sube la foto y recarga el perfil. Devuelve true si salió bien.
  Future<bool> subirFoto({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    state = await AsyncValue.guard(() async {
      await ref.read(perfilRepositoryProvider).subirFoto(
            bytes: bytes,
            nombreArchivo: nombreArchivo,
          );
      return ref.read(perfilRepositoryProvider).miPerfil();
    });
    return !state.hasError;
  }
}
