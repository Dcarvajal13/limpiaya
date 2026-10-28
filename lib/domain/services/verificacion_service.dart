import '../../core/errors/app_exception.dart';
import '../repositories/verificacion_repository.dart';

/// Reglas de negocio de HU-33 · Revisar verificaciones de identidad.
class VerificacionService {
  VerificacionService(this._repositorio);

  final VerificacionRepository _repositorio;

  /// Igual que la columna motivo_rechazo de la base de datos.
  static const largoMaximoMotivo = 300;

  /// Devuelve el error del motivo de rechazo, o null si es válido.
  static String? validarMotivo(String motivo) {
    final limpio = motivo.trim();
    if (limpio.isEmpty) return 'Indica el motivo'; // HU-33 c3
    if (limpio.length > largoMaximoMotivo) {
      return 'El motivo puede tener máximo $largoMaximoMotivo caracteres';
    }
    return null;
  }

  Future<void> aprobar(String id) => _repositorio.aprobar(id);

  Future<void> rechazar(String id, String motivo) async {
    final error = validarMotivo(motivo);
    if (error != null) throw AppException(error);
    await _repositorio.rechazar(id, motivo.trim());
  }
}
