import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_cliente_repository.dart';
import '../../data/repositories/supabase_perfil_repository.dart';
import '../../data/repositories/supabase_postulacion_repository.dart';
import '../../data/repositories/supabase_reputacion_repository.dart';
import '../../data/repositories/supabase_solicitud_repository.dart';
import '../../data/repositories/supabase_verificacion_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/repositories/perfil_repository.dart';
import '../../domain/repositories/postulacion_repository.dart';
import '../../domain/repositories/reputacion_repository.dart';
import '../../domain/repositories/solicitud_repository.dart';
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

final postulacionRepositoryProvider = Provider<PostulacionRepository>(
  (ref) => SupabasePostulacionRepository(ref.watch(supabaseClientProvider)),
);

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => SupabasePerfilRepository(ref.watch(supabaseClientProvider)),
);

final reputacionRepositoryProvider = Provider<ReputacionRepository>(
  (ref) => SupabaseReputacionRepository(ref.watch(supabaseClientProvider)),
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
