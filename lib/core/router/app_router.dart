import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/sesion_provider.dart';
import '../../presentation/screens/admin/admin_inicio_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/registro_screen.dart';
import '../../presentation/screens/cliente/mis_solicitudes_screen.dart';
import '../../presentation/screens/cliente/perfil_cliente_screen.dart';
import '../../presentation/screens/inicio/inicio_screen.dart';
import '../../presentation/screens/landing/landing_screen.dart';
import '../../presentation/screens/sistema_diseno/sistema_diseno_screen.dart';
import '../../presentation/screens/trabajadora/perfil_trabajadora_screen.dart';
import '../../presentation/screens/trabajadora/solicitudes_disponibles_screen.dart';
import '../di/providers.dart';
import 'redireccion.dart';
import 'rutas.dart';

/// Rutas de la app y protección de pantallas.
///
/// Las reglas de a dónde puede entrar cada quien están en redireccion.dart.
/// Este archivo solo las conecta con go_router.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);

  // Cada vez que cambia la sesión (alguien entra, sale o termina de cargar
  // su rol), el router vuelve a revisar las reglas.
  final refrescar = ValueNotifier<int>(0);
  ref.listen(sesionProvider, (anterior, siguiente) => refrescar.value++);
  ref.onDispose(refrescar.dispose);

  final router = GoRouter(
    initialLocation: Rutas.landing,
    refreshListenable: refrescar,
    redirect: (context, state) => redirigir(
      ubicacion: state.matchedLocation,
      haySesion: auth.usuarioActual != null,
      rol: ref.read(sesionProvider).value?.rol,
      perfilCompleto: ref.read(sesionProvider).value?.perfilCompleto ?? true,
    ),
    routes: [
      GoRoute(
        path: Rutas.landing,
        builder: (context, state) => const LandingScreen(),
      ),
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
      GoRoute(
        path: Rutas.inicioCliente,
        builder: (context, state) => const MisSolicitudesScreen(),
      ),
      GoRoute(
        path: Rutas.perfilCliente,
        builder: (context, state) => const PerfilClienteScreen(),
      ),
      GoRoute(
        path: Rutas.inicioTrabajadora,
        builder: (context, state) => const SolicitudesDisponiblesScreen(),
      ),
      GoRoute(
        path: Rutas.perfilTrabajadora,
        builder: (context, state) => const PerfilTrabajadoraScreen(),
      ),
      GoRoute(
        path: Rutas.inicioAdmin,
        builder: (context, state) => const AdminInicioScreen(),
      ),
      GoRoute(
        path: Rutas.sistemaDiseno,
        builder: (context, state) => const SistemaDisenoScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
