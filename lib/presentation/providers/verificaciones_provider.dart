import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/mi_verificacion.dart';
import '../../domain/entities/verificacion_pendiente.dart';
import 'sesion_provider.dart';

/// HU-33 · Verificaciones que esperan revisión, de la más antigua a la más
/// reciente. Después de aprobar o rechazar: `ref.invalidate(...)`.
final verificacionesPendientesProvider =
    FutureProvider.autoDispose<List<VerificacionPendiente>>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(verificacionRepositoryProvider).pendientes();
  },
  retry: (intentos, error) => null,
);

/// HU-21 · Última verificación de la trabajadora con sesión (null si nunca
/// envió documentos). Después de enviar: `ref.invalidate(...)`.
final miVerificacionProvider = FutureProvider.autoDispose<MiVerificacion?>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(verificacionRepositoryProvider).miUltima();
  },
  retry: (intentos, error) => null,
);
