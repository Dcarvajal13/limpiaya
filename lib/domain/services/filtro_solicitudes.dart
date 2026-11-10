import '../entities/solicitud_disponible.dart';
import '../entities/tipo_limpieza.dart';

/// Filtros que la trabajadora aplica a la lista (HU-11, criterio 2).
///
/// - [tipo] null significa "Todos".
/// - [zonasOcultas] son las zonas que desmarcó. Se guardan las desmarcadas
///   (y no las marcadas) para que, por defecto, se vean todas sus zonas.
/// - [fecha] es "Desde la fecha" (Figma W06): ese día y los siguientes.
///   null significa "cualquier fecha".
/// - [sinMascotas] true deja solo las casas sin mascotas.
class FiltroSolicitudes {
  const FiltroSolicitudes({
    this.tipo,
    this.zonasOcultas = const {},
    this.fecha,
    this.sinMascotas = false,
  });

  final TipoLimpieza? tipo;
  final Set<int> zonasOcultas;
  final DateTime? fecha;
  final bool sinMascotas;

  bool get hayFiltros =>
      tipo != null || zonasOcultas.isNotEmpty || fecha != null || sinMascotas;

  FiltroSolicitudes copiarCon({
    TipoLimpieza? tipo,
    bool quitarTipo = false,
    Set<int>? zonasOcultas,
    DateTime? fecha,
    bool quitarFecha = false,
    bool? sinMascotas,
  }) {
    return FiltroSolicitudes(
      tipo: quitarTipo ? null : (tipo ?? this.tipo),
      zonasOcultas: zonasOcultas ?? this.zonasOcultas,
      fecha: quitarFecha ? null : (fecha ?? this.fecha),
      sinMascotas: sinMascotas ?? this.sinMascotas,
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
  final fecha = filtro.fecha;
  // "Desde la fecha": desde el comienzo de ese día, sin importar la hora.
  final desde = fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);

  return solicitudes.where((solicitud) {
    if (filtro.tipo != null && solicitud.tipo != filtro.tipo) return false;
    if (filtro.zonasOcultas.contains(solicitud.zonaId)) return false;
    if (desde != null && solicitud.inicio.isBefore(desde)) return false;
    if (filtro.sinMascotas && solicitud.tieneMascotas) return false;
    return true;
  }).toList();
}
