import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/perfil_cliente_publico.dart';

/// HU-46 · Reputación y reseñas de un cliente, vistas por la trabajadora.
///
/// `null` cuando la cuenta no existe o no es de cliente.
final perfilClientePublicoProvider = FutureProvider.autoDispose
    .family<PerfilClientePublico?, String>(
  (ref, clienteId) =>
      ref.watch(clientePublicoRepositoryProvider).perfil(clienteId),
  retry: (intentos, error) => null,
);
