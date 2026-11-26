import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';

/// HU-42 · Aviso que debe ver el login cuando la cuenta está desactivada.
///
/// Vive fuera de la pantalla porque al cerrar la sesión el login se vuelve a
/// crear y perdería su estado: sin esto, la persona veía el formulario vacío
/// y sin explicación.
final avisoCuentaDesactivadaProvider =
    NotifierProvider<AvisoCuentaDesactivadaNotifier, String?>(
  AvisoCuentaDesactivadaNotifier.new,
);

class AvisoCuentaDesactivadaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void mostrar(String mensaje) => state = mensaje;

  void limpiar() => state = null;
}

/// HU-39 y HU-42 · Acciones sobre la propia cuenta.
///
/// Los métodos devuelven `null` si salió bien, o el mensaje que debe ver la
/// persona. Se usan con `ref.read(...)` desde un botón, como
/// `completarServicioProvider`.
final cuentaProvider =
    NotifierProvider<CuentaNotifier, AsyncValue<void>>(CuentaNotifier.new);

class CuentaNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// HU-41 · Devuelve el error a mostrar, o null si los datos se guardaron.
  Future<String?> actualizarDatos({
    required String nombre,
    required String telefono,
  }) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(cuentaRepositoryProvider).actualizarDatos(
            nombre: nombre,
            telefono: telefono,
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      return _mensaje(
        resultado.error,
        'No pudimos guardar tus datos. Intenta de nuevo.',
      );
    }
    return null;
  }

  /// HU-39 · Devuelve el error a mostrar, o null si la contraseña cambió.
  Future<String?> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(cuentaRepositoryProvider).cambiarContrasena(
            actual: actual,
            nueva: nueva,
          ),
    );
    state = resultado;

    if (resultado.hasError) {
      return _mensaje(
        resultado.error,
        'No pudimos cambiar tu contraseña. Intenta de nuevo.',
      );
    }
    return null;
  }

  /// HU-42 · Devuelve el error a mostrar, o null si la cuenta quedó inactiva.
  Future<String?> desactivar() async {
    state = const AsyncLoading();

    final resultado = await AsyncValue.guard(
      () => ref.read(cuentaRepositoryProvider).desactivar(),
    );
    state = resultado;

    if (resultado.hasError) {
      return _mensaje(
        resultado.error,
        'No pudimos desactivar tu cuenta. Intenta de nuevo.',
      );
    }
    return null;
  }

  String _mensaje(Object? error, String porDefecto) =>
      error is AppException ? error.mensaje : porDefecto;
}
