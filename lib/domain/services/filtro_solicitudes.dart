import '../entities/solicitud_disponible.dart';
import '../entities/tipo_limpieza.dart';

/// Filtros que la trabajadora aplica a la lista (HU-11, criterio 2).
///
/// - [tipo] null significa "Todos".
/// - [zonasOcultas] son las zonas que desmarcó. Se guardan las desmarcadas
///   (y no las marcadas) para que, por defecto, se vean todas sus zonas.
/// - [fecha] null significa "cualquier fecha".
class FiltroSolicitudes {
  const FiltroSolicitudes({
    this.tipo,
    this.zonasOcultas = const {},
    this.fecha,
  });

  final TipoLimpieza? tipo;
  final Set<int> zonasOcultas;
  final DateTime? fecha;

  bool get hayFiltros =>
      tipo != null || zonasOcultas.isNotEmpty || fecha != null;

  FiltroSolicitudes copiarCon({
    TipoLimpieza? tipo,
    bool quitarTipo = false,
    Set<int>? zonasOcultas,
    DateTime? fecha,
    bool quitarFecha = false,
  }) {
    return FiltroSolicitudes(
      tipo: quitarTipo ? null : (tipo ?? this.tipo),
      zonasOcultas: zonasOcultas ?? this.zonasOcultas,
      fecha: quitarFecha ? null : (fecha ?? this.fecha),
    );
  }
}

/// Aplica los [filtro]s a la lista. No modifica la lista original.
///
/// Es una función sin Flutter ni Supabase para poder probarla fácil
/// (test/domain/services/filtro_solicitudes_test.dart).
List<SolicitudDisponible> filtrarSolicitudes(
  List<SolicitudDisponible> solicitudes,
  FiltroSolicitudes filtro,
) {
  bool mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  return solicitudes.where((solicitud) {
    if (filtro.tipo != null && solicitud.tipo != filtro.tipo) return false;
    if (filtro.zonasOcultas.contains(solicitud.zonaId)) return false;
    final fecha = filtro.fecha;
    if (fecha != null && !mismoDia(solicitud.inicio, fecha)) return false;
    return true;
  }).toList();
}
