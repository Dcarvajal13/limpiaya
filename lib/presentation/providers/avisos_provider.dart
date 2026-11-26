import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/aviso.dart';
import '../../domain/entities/correo_aviso.dart';
import '../../domain/services/aviso_service.dart';
import 'sesion_provider.dart';

/// HU-50 · Avisos del usuario en vivo (Realtime).
final avisosProvider = StreamProvider.autoDispose<List<Aviso>>(
  (ref) {
    final sesion = ref.watch(sesionProvider).value;
    if (sesion == null) return Stream.value(const []);
    return ref.watch(avisoRepositoryProvider).streamAvisos();
  },
  retry: (intentos, error) => null,
);

/// HU-50 · Cantidad de avisos sin leer para el contador de la campana.
final avisosNoLeidosProvider = Provider.autoDispose<int>((ref) {
  final avisos = ref.watch(avisosProvider).value;
  if (avisos == null) return 0;
  return AvisoService.contarNoLeidos(avisos);
});

/// HU-49 · Historial/cola de avisos por correo del usuario.
final correosAvisoProvider = FutureProvider.autoDispose<List<CorreoAviso>>(
  (ref) async {
    final sesion = await ref.watch(sesionProvider.future);
    if (sesion == null) return const [];
    return ref.watch(avisoRepositoryProvider).misCorreos();
  },
  retry: (intentos, error) => null,
);
