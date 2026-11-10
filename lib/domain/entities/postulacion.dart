import 'estado_postulacion.dart';
import 'estado_solicitud.dart';
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
    this.direccion,
    this.puntoReferencia,
    this.estadoSolicitud,
    this.motivoCancelacion,
    this.canceladaPorMi = false,
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

  /// HU-15 c3 · Dirección exacta y punto de referencia. Solo vienen cuando el
  /// cliente la eligió (Aceptada): antes, la base no deja leerlos.
  final String? direccion;
  final String? puntoReferencia;

  /// Estado real de la solicitud. Una postulación Aceptada puede ser de un
  /// servicio Asignado o ya Completado: solo el Asignado se cancela (HU-28).
  final EstadoSolicitud? estadoSolicitud;

  /// HU-28 c1 · Motivo de la cancelación, si la solicitud se canceló.
  final String? motivoCancelacion;

  /// HU-28 · La canceló ella misma (y no el cliente).
  final bool canceladaPorMi;
}
