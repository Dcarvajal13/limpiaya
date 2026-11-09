import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/postulante.dart';

/// HU-14 · Postulantes de una solicitud. Se vuelve a cargar cada vez que se
/// abre la pantalla, para no mostrar a quien ya se retiró (c2).
final postulantesProvider =
    FutureProvider.autoDispose.family<List<Postulante>, String>(
  (ref, solicitudId) =>
      ref.watch(postulacionRepositoryProvider).postulantesDe(solicitudId),
);