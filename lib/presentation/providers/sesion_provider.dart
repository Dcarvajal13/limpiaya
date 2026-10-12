import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/sesion.dart';

/// Sesión actual: rol, nombre y estado del perfil (HU-02A / HU-02B).
///
/// Se recarga sola cada vez que alguien inicia o cierra sesión.
/// - `ref.watch(sesionProvider).value?.nombre` → nombre de quien entró.
/// - `ref.invalidate(sesionProvider)` → volver a cargarla (por ejemplo
///   después de completar el perfil).
final sesionProvider =
    AsyncNotifierProvider<SesionNotifier, Sesion?>(SesionNotifier.new);

class SesionNotifier extends AsyncNotifier<Sesion?> {
  /// Usuario con el que se cargó la sesión por última vez.
  String? _usuarioCargado;

  @override
  Future<Sesion?> build() async {
    final auth = ref.watch(authRepositoryProvider);
    _usuarioCargado = auth.usuarioActual?.id;

    // Supabase avisa de muchos eventos (por ejemplo, cuando renueva el
    // token). Solo recargamos si cambió la persona.
    final suscripcion = auth.cambiosDeSesion().listen((usuario) {
      if (usuario?.id != _usuarioCargado) ref.invalidateSelf();
    });
    ref.onDispose(suscripcion.cancel);

    if (_usuarioCargado == null) return null;
    return auth.obtenerSesion();
  }
}
