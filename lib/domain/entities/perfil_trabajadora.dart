import 'tipo_limpieza.dart';
import 'zona.dart';

/// Perfil de la trabajadora (HU-04): zonas, servicios, experiencia,
/// tarifa de referencia y foto.
///
/// Es una entidad del dominio: no sabe nada de Supabase.
class PerfilTrabajadora {
  const PerfilTrabajadora({
    required this.zonas,
    required this.servicios,
    this.experienciaAnios,
    this.tarifaReferencia,
    this.descripcion,
    this.fotoUrl,
  });

  /// Zonas donde trabaja (tabla `trabajadora_zonas`).
  final List<Zona> zonas;

  /// Servicios que ofrece (tabla `trabajadora_servicios`).
  final List<TipoLimpieza> servicios;

  /// Años de experiencia, o null si no los indicó.
  final int? experienciaAnios;

  /// Tarifa por hora de referencia, opcional (HU-04, criterio 5).
  final double? tarifaReferencia;

  /// Texto libre describiendo su trabajo.
  final String? descripcion;

  /// Dirección pública de la foto (bucket `avatars`), o null si no tiene.
  final String? fotoUrl;

  /// Mismo cálculo que `perfil_completo` en `mi_sesion()`: tener al menos
  /// una zona y un servicio (HU-04, criterio 1 y 2).
  bool get completo => zonas.isNotEmpty && servicios.isNotEmpty;

  /// "Desde $X por hora" (HU-04, criterio 5), o null si no puso tarifa.
  String? get tarifaTexto {
    final tarifa = tarifaReferencia;
    if (tarifa == null || tarifa <= 0) return null;
    final entera = tarifa == tarifa.roundToDouble();
    return 'Desde \$${entera ? tarifa.toInt() : tarifa} por hora';
  }
}
