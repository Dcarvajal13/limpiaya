import 'tipo_limpieza.dart';

/// Una reseña visible en el perfil público (HU-06).
///
/// La vista `resenas_publicas` solo devuelve las que ya se pueden mostrar:
/// cuando la otra parte también calificó o cuando pasaron 7 días.
class ResenaPublica {
  const ResenaPublica({
    required this.estrellas,
    required this.autorNombre,
    this.comentario,
    this.createdAt,
  });

  /// De 1 a 5.
  final int estrellas;

  /// Nombre de quien la escribió (cliente o trabajadora).
  final String autorNombre;

  final String? comentario;
  final DateTime? createdAt;
}

/// Perfil público de una trabajadora (HU-06), tal como lo ve un cliente.
///
/// Sale de la vista `trabajadoras_publicas`, que **no** incluye teléfono,
/// correo ni dirección. Es justo lo que hace falta para decidir si contratarla.
class PerfilPublico {
  const PerfilPublico({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    this.experienciaAnios,
    this.tarifaReferencia,
    this.descripcion,
    this.verificada = false,
    this.zonas = const [],
    this.servicios = const [],
    this.promedio,
    this.totalResenas = 0,
    this.serviciosCompletados = 0,
    this.resenas = const [],
  });

  final String id;
  final String nombre;
  final String? fotoUrl;

  final int? experienciaAnios;

  /// Tarifa de referencia en USD por hora, si la cargó.
  final double? tarifaReferencia;

  final String? descripcion;

  /// Insignia "Identidad verificada" (HU-21).
  final bool verificada;

  /// Nombres de las urbanizaciones donde trabaja.
  final List<String> zonas;

  /// Tipos de limpieza que ofrece.
  final List<TipoLimpieza> servicios;

  final double? promedio;
  final int totalResenas;
  final int serviciosCompletados;

  final List<ResenaPublica> resenas;

  /// HU-06 c2: sin reseñas se muestra "Aún no tiene reseñas".
  bool get tieneResenas => promedio != null && totalResenas > 0;
}
