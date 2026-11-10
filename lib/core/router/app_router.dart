import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/recuperacion_provider.dart';
import '../../presentation/providers/sesion_provider.dart';
import '../../presentation/screens/admin/admin_inicio_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/nueva_contrasena_screen.dart';
import '../../presentation/screens/auth/recuperar_contrasena_screen.dart';
import '../../presentation/screens/auth/registro_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/chat/mensajes_screen.dart';
import '../../presentation/screens/cliente/buscar_trabajadoras_screen.dart';
import '../../presentation/screens/cliente/mis_solicitudes_screen.dart';
import '../../presentation/screens/cliente/perfil_cliente_screen.dart';
import '../../presentation/screens/cliente/postulantes_screen.dart';
import '../../presentation/screens/cliente/publicar_solicitud_screen.dart';
import '../../presentation/screens/inicio/inicio_screen.dart';
import '../../presentation/screens/perfil/perfil_publico_screen.dart';
import '../../presentation/screens/landing/landing_screen.dart';
import '../../presentation/screens/sistema_diseno/sistema_diseno_screen.dart';
import '../../presentation/screens/trabajadora/detalle_solicitud_screen.dart';
import '../../presentation/screens/trabajadora/mi_reputacion_screen.dart';
import '../../presentation/screens/trabajadora/mis_servicios_screen.dart';
import '../../presentation/screens/trabajadora/servicio_agendado_screen.dart';
import '../../presentation/screens/trabajadora/perfil_cliente_publico_screen.dart';
import '../../presentation/screens/trabajadora/perfil_trabajadora_screen.dart';
import '../../presentation/screens/trabajadora/solicitudes_disponibles_screen.dart';
import '../../presentation/screens/trabajadora/verificacion_identidad_screen.dart';
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
  ref.listen(
    recuperandoContrasenaProvider,
    (anterior, siguiente) => refrescar.value++,
  );
  ref.onDispose(refrescar.dispose);

  final router = GoRouter(
    initialLocation: Rutas.landing,
    refreshListenable: refrescar,
    redirect: (context, state) => redirigir(
      ubicacion: state.matchedLocation,
      haySesion: auth.usuarioActual != null,
      rol: ref.read(sesionProvider).value?.rol,
      perfilCompleto: ref.read(sesionProvider).value?.perfilCompleto ?? true,
      recuperandoContrasena: ref.read(recuperandoContrasenaProvider),
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
        path: Rutas.recuperarContrasena,
        builder: (context, state) => const RecuperarContrasenaScreen(),
      ),
      GoRoute(
        path: Rutas.nuevaContrasena,
        builder: (context, state) => const NuevaContrasenaScreen(),
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
        path: Rutas.misServicios,
        builder: (context, state) => const MisServiciosScreen(),
      ),
      // HU-31 / HU-61 · Mis reseñas, mis respuestas y mi nivel.
      GoRoute(
        path: Rutas.miReputacion,
        builder: (context, state) => const MiReputacionScreen(),
      ),
      GoRoute(
        path: Rutas.detalleSolicitudPatron,
        builder: (context, state) => DetalleSolicitudScreen(
          solicitudId: state.pathParameters['id']!,
        ),
      ),
      // HU-46 · Perfil del cliente, visto por la trabajadora.
      GoRoute(
        path: Rutas.perfilClientePublicoPatron,
        builder: (context, state) => PerfilClientePublicoScreen(
          clienteId: state.pathParameters['id']!,
        ),
      ),
      // HU-16 · Detalle del servicio agendado, desde la trabajadora.
      GoRoute(
        path: Rutas.servicioAgendadoPatron,
        builder: (context, state) => ServicioAgendadoScreen(
          solicitudId: state.pathParameters['id']!,
        ),
      ),
      // HU-16 · El mismo detalle, desde el cliente dueño del servicio.
      GoRoute(
        path: Rutas.servicioClientePatron,
        builder: (context, state) => ServicioAgendadoScreen(
          solicitudId: state.pathParameters['id']!,
        ),
      ),
      // HU-38 · Chat del servicio y lista de conversaciones.
      GoRoute(
        path: Rutas.chatServicioPatron,
        builder: (context, state) => ChatScreen(
          solicitudId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Rutas.mensajesCliente,
        builder: (context, state) => const MensajesScreen(),
      ),
      GoRoute(
        path: Rutas.mensajesTrabajadora,
        builder: (context, state) => const MensajesScreen(),
      ),
      GoRoute(
        path: Rutas.verificacionTrabajadora,
        builder: (context, state) => const VerificacionIdentidadScreen(),
      ),
      GoRoute(
        path: Rutas.inicioAdmin,
        builder: (context, state) => const AdminInicioScreen(),
      ),
      GoRoute(
        path: Rutas.sistemaDiseno,
        builder: (context, state) => const SistemaDisenoScreen(),
      ),
      GoRoute(
        path: Rutas.publicarSolicitud,
        builder: (context, state) => const PublicarSolicitudScreen(),
      ),
      GoRoute(
        path: Rutas.editarSolicitudPatron,
        builder: (context, state) => PublicarSolicitudScreen(
          solicitudId: state.pathParameters['id'],
        ),
      ),
      // HU-44 · Repetir una solicitud anterior.
      GoRoute(
        path: Rutas.repetirSolicitudPatron,
        builder: (context, state) => PublicarSolicitudScreen(
          repetirDe: state.pathParameters['id'],
        ),
      ),
      // HU-14 · Postulantes de una solicitud del cliente.
      GoRoute(
        path: Rutas.postulantesPatron,
        builder: (context, state) =>
            PostulantesScreen(solicitudId: state.pathParameters['id']!),
      ),
      // HU-25 · Buscar trabajadoras e invitarlas.
      GoRoute(
        path: Rutas.buscarTrabajadoras,
        builder: (context, state) => const BuscarTrabajadorasScreen(),
      ),
      // HU-06 · Perfil público de una trabajadora, sin teléfono ni correo.
      GoRoute(
        path: Rutas.perfilPublicoTrabajadoraPatron,
        builder: (context, state) => PerfilPublicoScreen(
          trabajadoraId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});