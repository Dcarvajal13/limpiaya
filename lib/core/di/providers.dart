import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

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
