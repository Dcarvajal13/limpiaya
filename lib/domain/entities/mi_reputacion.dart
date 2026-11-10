import '../services/nivel_service.dart';
import 'perfil_publico.dart';

/// "Mi reputación" de la trabajadora con sesión (HU-31, HU-61).
///
/// Las reseñas son solo las ya visibles (HU-29 c4): cuando ambas partes
/// calificaron o pasaron 7 días.
class MiReputacion {
  const MiReputacion({
    this.promedio,
    this.totalResenas = 0,
    this.serviciosCompletados = 0,
    this.resenas = const [],
    this.destacada = false,
    this.cancelacionesTardias = 0,
  });

  /// Promedio de 1 a 5, o null si todavía no tiene reseñas visibles.
  final double? promedio;
  final int totalResenas;
  final int serviciosCompletados;

  /// Reseñas que me dejaron, de la más nueva a la más vieja.
  final List<ResenaPublica> resenas;

  /// HU-61 · Tengo la insignia "Destacada" (la calcula la base).
  final bool destacada;

  /// HU-61 · Cancelaciones tardías (HU-28) en los últimos 30 días.
  final int cancelacionesTardias;

  bool get cumpleServicios =>
      serviciosCompletados >= NivelService.minServicios;
  bool get cumplePromedio => (promedio ?? 0) >= NivelService.minPromedio;
  bool get cumpleCancelaciones => cancelacionesTardias == 0;
}
