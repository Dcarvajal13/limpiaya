import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/registro_screen.dart';
import '../../presentation/screens/inicio/inicio_screen.dart';
import '../di/providers.dart';
import 'rutas.dart';

/// Rutas de la app y protección de pantallas.
///
/// Regla actual:
/// - Sin sesión → solo puede ver login y registro (HU-03, criterio 2).
/// - Con sesión → si intenta abrir login o registro, va a inicio.
///
/// TODO(HU-02A/HU-02B): cuando exista el perfil con rol (HD-03), mandar al
/// cliente a "Mis solicitudes" y a la trabajadora a "Solicitudes disponibles".
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final refrescar = _RefrescarConStream(auth.cambiosDeSesion());
  ref.onDispose(refrescar.dispose);

  return GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refrescar,
    redirect: (context, state) {
      final haySesion = auth.usuarioActual != null;
      final esPublica = Rutas.publicas.contains(state.matchedLocation);

      if (!haySesion && !esPublica) return Rutas.login;
      if (haySesion && esPublica) return Rutas.inicio;
      return null;
    },
    routes: [
      GoRoute(
        path: Rutas.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Rutas.registro,
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const InicioScreen(),
      ),
    ],
  );
});

/// Hace que el router vuelva a revisar las reglas cada vez que alguien
/// inicia o cierra sesión.
class _RefrescarConStream extends ChangeNotifier {
  _RefrescarConStream(Stream<dynamic> stream) {
    _suscripcion = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _suscripcion;

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
