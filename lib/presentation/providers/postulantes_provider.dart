import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/postulante.dart';
import '../../domain/services/nivel_service.dart';

/// HU-14 · Postulantes de una solicitud. Se vuelve a cargar cada vez que se
/// abre la pantalla, para no mostrar a quien ya se retiró (c2).
///
/// HU-61 c2 · Las trabajadoras destacadas salen primero.
final postulantesProvider =
    FutureProvider.autoDispose.family<List<Postulante>, String>(
  (ref, solicitudId) async => NivelService.ordenarPostulantes(
    await ref.watch(postulacionRepositoryProvider).postulantesDe(solicitudId),
  ),
);