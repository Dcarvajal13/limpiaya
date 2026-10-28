import 'estado_postulacion.dart';
import 'tipo_limpieza.dart';

/// Postulación de la trabajadora a una solicitud (HU-13).
///
/// Junta lo de la postulación con lo que la trabajadora puede ver de la
/// solicitud: nunca incluye la dirección exacta ni el teléfono.
class Postulacion {
  const Postulacion({
    required this.id,
    required this.solicitudId,
    required this.estado,
    required this.tipo,
    required this.zona,
    required this.inicio,
    required this.horasEstimadas,
    required this.pagoOfrecido,
    this.clienteNombre,
    this.clienteFotoUrl,
    this.creadaEn,
  });

  final String id;
  final String solicitudId;

  /// Estado ya resuelto (ver [EstadoPostulacion.resolver]).
  final EstadoPostulacion estado;

  final TipoLimpieza tipo;
  final String zona;

  /// Fecha y hora de inicio en hora local.
  final DateTime inicio;
  final double horasEstimadas;

  /// Lo que recibe la trabajadora, en USD.
  final double pagoOfrecido;

  /// Nombre del cliente (vista `perfiles_publicos`), o null si no se pudo leer.
  final String? clienteNombre;
  final String? clienteFotoUrl;

  final DateTime? creadaEn;
}
