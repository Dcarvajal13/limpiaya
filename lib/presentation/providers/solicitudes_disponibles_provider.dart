import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/solicitud_disponible.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/entities/zona.dart';
import '../../domain/services/filtro_solicitudes.dart';

/// Estado de la pantalla "Trabajos disponibles" (HU-11).
///
/// - `ref.watch(solicitudesDisponiblesProvider)` → todas las solicitudes
///   de las zonas de la trabajadora.
/// - `ref.watch(solicitudesFiltradasProvider)` → las mismas, ya filtradas.
/// - `ref.invalidate(solicitudesDisponiblesProvider)` → volver a cargarlas.

/// Zonas de la trabajadora (para el filtro "Mis zonas").
final misZonasProvider = FutureProvider<List<Zona>>(
  (ref) => ref.watch(solicitudRepositoryProvider).misZonas(),
  // Si falla, que se vea el error de una vez en vez de reintentar a ciegas.
  retry: (intentos, error) => null,
);

final solicitudesDisponiblesProvider =
    FutureProvider<List<SolicitudDisponible>>(
      (ref) => ref.watch(solicitudRepositoryProvider).disponibles(),
      retry: (intentos, error) => null,
    );

/// Filtros elegidos por la trabajadora. Viven mientras la pantalla esté abierta.
final filtroSolicitudesProvider =
    NotifierProvider.autoDispose<FiltroSolicitudesNotifier, FiltroSolicitudes>(
      FiltroSolicitudesNotifier.new,
    );

class FiltroSolicitudesNotifier extends Notifier<FiltroSolicitudes> {
  @override
  FiltroSolicitudes build() => const FiltroSolicitudes();

  /// null = "Todos".
  void elegirTipo(TipoLimpieza? tipo) {
    state = tipo == null
        ? state.copiarCon(quitarTipo: true)
        : state.copiarCon(tipo: tipo);
  }

  void alternarZona(int zonaId) {
    final ocultas = {...state.zonasOcultas};
    if (!ocultas.add(zonaId)) ocultas.remove(zonaId);
    state = state.copiarCon(zonasOcultas: ocultas);
  }

  /// null = cualquier fecha.
  void elegirFecha(DateTime? fecha) {
    state = fecha == null
        ? state.copiarCon(quitarFecha: true)
        : state.copiarCon(fecha: fecha);
  }

  void limpiar() => state = const FiltroSolicitudes();
}

/// Solicitudes con los filtros aplicados (HU-11, criterio 2).
final solicitudesFiltradasProvider =
    Provider.autoDispose<AsyncValue<List<SolicitudDisponible>>>((ref) {
      final filtro = ref.watch(filtroSolicitudesProvider);
      return ref
          .watch(solicitudesDisponiblesProvider)
          .whenData((lista) => filtrarSolicitudes(lista, filtro));
    });
