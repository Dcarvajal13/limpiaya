import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/servicio_agendado.dart';
import 'sesion_provider.dart';

/// HU-16 · Servicios agendados, completados y cancelados de la trabajadora
/// que inició sesión.
final misServiciosProvider =
    FutureProvider.autoDispose<List<ServicioAgendado>>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(servicioRepositoryProvider).misServicios();
  },
  retry: (intentos, error) => null,
);

/// HU-16 c2 · Detalle de un servicio concreto, con dirección y contraparte.
final servicioAgendadoProvider =
    FutureProvider.autoDispose.family<ServicioAgendado?, String>(
  (ref, solicitudId) async {
    await ref.watch(sesionProvider.future);
    return ref
        .watch(servicioRepositoryProvider)
        .servicioAgendado(solicitudId);
  },
  retry: (intentos, error) => null,
);
