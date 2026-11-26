import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/sesion.dart';
import 'cuenta_provider.dart';

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

    final sesion = await auth.obtenerSesion();

    // HU-42: una cuenta desactivada no usa la app, entre por donde entre.
    // Se revisa aquí, y no solo en el login, porque la sesión puede tardar
    // un instante en quedar disponible al iniciar sesión en la web.
    if (sesion != null && !sesion.activo) {
      ref
          .read(avisoCuentaDesactivadaProvider.notifier)
          .mostrar(const CuentaDesactivadaException().mensaje);
      await auth.cerrarSesion();
      return null;
    }
    if (sesion != null && sesion.suspendido) {
      ref
          .read(avisoCuentaDesactivadaProvider.notifier)
          .mostrar(CuentaSuspendidaException(sesion.motivoSuspension).mensaje);
      await auth.cerrarSesion();
      return null;
    }
    return sesion;
  }
}
