import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_busqueda_trabajadoras_repository.dart';
import '../../data/repositories/supabase_calificacion_repository.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../data/repositories/supabase_cliente_publico_repository.dart';
import '../../data/repositories/supabase_cliente_repository.dart';
import '../../data/repositories/supabase_trabajadora_publica_repository.dart';
import '../../data/repositories/supabase_mi_reputacion_repository.dart';
import '../../data/repositories/supabase_perfil_repository.dart';
import '../../data/repositories/supabase_postulacion_repository.dart';
import '../../data/repositories/supabase_reputacion_repository.dart';
import '../../data/repositories/supabase_servicio_repository.dart';
import '../../data/repositories/supabase_solicitud_repository.dart';
import '../../data/repositories/supabase_verificacion_correo_repository.dart';
import '../../data/repositories/supabase_verificacion_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/busqueda_trabajadoras_repository.dart';
import '../../domain/repositories/calificacion_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/cliente_publico_repository.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/repositories/mi_reputacion_repository.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/repositories/postulacion_repository.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/repositories/servicio_repository.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../../domain/repositories/trabajadora_publica_repository.dart';
import '../../domain/repositories/verificacion_correo_repository.dart';
import '../../domain/repositories/verificacion_repository.dart';
import '../../domain/services/registro_service.dart';
import '../../domain/services/solicitud_service.dart';
import '../../domain/services/verificacion_service.dart';
/// "Inyección de dependencias": aquí se decide qué implementación
/// usa cada contrato del dominio.
///
/// Es el único archivo que conoce a la vez domain y data. Las pantallas
/// piden `ref.watch(authRepositoryProvider)` y reciben un AuthRepository,
/// sin saber que por dentro es Supabase.
///
/// Cuando agreguen un repositorio nuevo (por ejemplo SolicitudRepository),
/// se registra aquí de la misma forma.

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider)),
);

final solicitudRepositoryProvider = Provider<SolicitudRepository>(
  (ref) => SupabaseSolicitudRepository(ref.watch(supabaseClientProvider)),
);

final clienteRepositoryProvider = Provider<ClienteRepository>(
  (ref) => SupabaseClienteRepository(ref.watch(supabaseClientProvider)),
);

final trabajadoraPublicaRepositoryProvider =
    Provider<TrabajadoraPublicaRepository>(
  (ref) => SupabaseTrabajadoraPublicaRepository(
    ref.watch(supabaseClientProvider),
  ),
);

/// HU-46 · Reputación y reseñas de un cliente, vistas por la trabajadora.
final clientePublicoRepositoryProvider = Provider<ClientePublicoRepository>(
  (ref) => SupabaseClientePublicoRepository(ref.watch(supabaseClientProvider)),
);

final postulacionRepositoryProvider = Provider<PostulacionRepository>(
  (ref) => SupabasePostulacionRepository(ref.watch(supabaseClientProvider)),
);

/// Servicios agendados: elegir, completar y cancelar (HU-15, HU-17, HU-28).
final servicioRepositoryProvider = Provider<ServicioRepository>(
  (ref) => SupabaseServicioRepository(ref.watch(supabaseClientProvider)),
);

/// Calificaciones de un servicio Completado (HU-29, HU-30).
final calificacionRepositoryProvider = Provider<CalificacionRepository>(
  (ref) => SupabaseCalificacionRepository(ref.watch(supabaseClientProvider)),
);

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => SupabasePerfilRepository(ref.watch(supabaseClientProvider)),
);

final reputacionRepositoryProvider = Provider<ReputacionRepository>(
  (ref) => SupabaseReputacionRepository(ref.watch(supabaseClientProvider)),
);

/// HU-38 · Chat de un servicio entre el cliente y la trabajadora.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => SupabaseChatRepository(ref.watch(supabaseClientProvider)),
);

/// HU-25 · Buscar trabajadoras e invitarlas a una solicitud.
final busquedaTrabajadorasRepositoryProvider =
    Provider<BusquedaTrabajadorasRepository>(
  (ref) => SupabaseBusquedaTrabajadorasRepository(
    ref.watch(supabaseClientProvider),
  ),
);

/// HU-31 · Mi reputación: mis reseñas y mis respuestas.
final miReputacionRepositoryProvider = Provider<MiReputacionRepository>(
  (ref) => SupabaseMiReputacionRepository(ref.watch(supabaseClientProvider)),
);

final registroServiceProvider = Provider<RegistroService>(
  (ref) => RegistroService(ref.watch(authRepositoryProvider)),
);

final solicitudServiceProvider = Provider<SolicitudService>(
  (ref) => SolicitudService(ref.watch(solicitudRepositoryProvider)),
);

final verificacionRepositoryProvider = Provider<VerificacionRepository>(
  (ref) => SupabaseVerificacionRepository(ref.watch(supabaseClientProvider)),
);

final verificacionServiceProvider = Provider<VerificacionService>(
  (ref) => VerificacionService(ref.watch(verificacionRepositoryProvider)),
);

/// HU-40 · Reenviar el enlace para verificar el correo.
final verificacionCorreoRepositoryProvider =
    Provider<VerificacionCorreoRepository>(
  (ref) => SupabaseVerificacionCorreoRepository(
    ref.watch(supabaseClientProvider),
  ),
);
