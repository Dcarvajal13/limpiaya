import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/perfil_publico.dart';
import 'sesion_provider.dart';

/// HU-06 · Perfil público de una trabajadora.
///
/// `null` cuando la cuenta no existe o no es de trabajadora.
final perfilPublicoProvider =
    FutureProvider.autoDispose.family<PerfilPublico?, String>((ref, id) async {
      await ref.watch(sesionProvider.future);
      return ref.watch(trabajadoraPublicaRepositoryProvider).perfil(id);
    }, retry: (intentos, error) => null);
