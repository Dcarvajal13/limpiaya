import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/solicitud.dart';
import 'sesion_provider.dart';

/// Solicitudes creadas por el cliente que inició sesión (HU-08).
///
/// - Ordenadas por fecha de inicio del servicio (criterio 1).
/// - Muestra el número de postulantes (criterio 2).
/// - Si no hay solicitudes, se muestra el estado vacío (criterio 3).
final misSolicitudesProvider = FutureProvider.autoDispose<List<Solicitud>>(
  (ref) async {
    await ref.watch(sesionProvider.future);
    return ref.watch(solicitudRepositoryProvider).misSolicitudes();
  },
  retry: (intentos, error) => null,
);
