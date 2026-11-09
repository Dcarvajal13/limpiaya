import 'estado_postulacion.dart';

/// Una trabajadora que se postuló a una solicitud del cliente (HU-14).
class Postulante {
  const Postulante({
    required this.postulacionId,
    required this.trabajadoraId,
    required this.nombre,
    required this.estado,
    required this.fecha,
    this.fotoUrl,
    this.promedio,
    this.mensaje,
    this.verificada = true,
    this.experienciaAnios,
    this.serviciosCompletados = 0,
    this.totalResenas = 0,
  });

  final String postulacionId;
  final String trabajadoraId;
  final String nombre;
  final EstadoPostulacion estado;

  /// Cuándo se postuló, en la hora local de quien la mira.
  final DateTime fecha;
  final String? fotoUrl;

  /// Promedio de 1 a 5, o null si todavía no tiene reseñas.
  final double? promedio;

  /// Mensaje opcional que dejó al postularse (HU-12).
  final String? mensaje;

  /// Identidad aprobada (vista trabajadoras_publicas).
  final bool verificada;

  /// Años de experiencia que puso en su perfil (HU-04), si los indicó.
  final int? experienciaAnios;

  /// Servicios que ya completó en LimpiaYa.
  final int serviciosCompletados;

  /// Reseñas visibles que ha recibido (HU-29 c4).
  final int totalResenas;
}