import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/rol_usuario.dart';

/// Controlador de la pantalla de registro (HU-01).
/// Guarda si está cargando, si hubo error o si terminó bien.
final registroControllerProvider =
    NotifierProvider<RegistroController, AsyncValue<void>>(
  RegistroController.new,
);

class RegistroController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Devuelve true si la cuenta se creó.
  Future<bool> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario? rol,
    required bool aceptoTerminos,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(registroServiceProvider).registrar(
            nombre: nombre,
            email: email,
            telefono: telefono,
            password: password,
            rol: rol,
            aceptoTerminos: aceptoTerminos,
          ),
    );
    return !state.hasError;
  }
}