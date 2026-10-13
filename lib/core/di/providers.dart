import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_solicitud_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../../domain/services/registro_service.dart';

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

final registroServiceProvider = Provider<RegistroService>(
  (ref) => RegistroService(ref.watch(authRepositoryProvider)),
);