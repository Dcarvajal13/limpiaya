import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/postulacion.dart';
import 'sesion_provider.dart';

/// Postulaciones de la trabajadora que inició sesión (HU-13).
///
/// Cada una trae su estado: Pendiente, Aceptada, No seleccionada o
/// Solicitud cancelada (criterios 1 y 2).
final misPostulacionesProvider = FutureProvider.autoDispose<List<Postulacion>>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(postulacionRepositoryProvider).misPostulaciones();
  },
  retry: (intentos, error) => null,
);
