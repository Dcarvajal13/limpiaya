import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../entities/archivo_foto.dart';
import '../repositories/verificacion_repository.dart';

/// Reglas de negocio de HU-21 · Verificar mi identidad y
/// HU-33 · Revisar verificaciones de identidad.
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

  /// Devuelve el error de una foto, o null si sirve (JPG o PNG, hasta 5 MB,
  /// igual que la foto de perfil de HU-04).
  static String? validarFoto(ArchivoFoto foto) {
    if (!foto.esJpg && !foto.esPng) return 'La foto debe ser JPG o PNG';
    if (foto.bytes.isEmpty) return 'La foto está vacía. Elige otra.';
    if (foto.bytes.length > AppConstants.tamanoMaximoFotoBytes) {
      return 'La foto no puede pasar de 5 MB';
    }
    return null;
  }

  /// HU-21 c1 · Envía la cédula y la selfie a revisión.
  Future<void> enviar({ArchivoFoto? cedula, ArchivoFoto? selfie}) async {
    if (cedula == null) throw const AppException('Sube la foto de tu cédula');
    if (selfie == null) {
      throw const AppException('Sube la selfie sosteniendo tu cédula');
    }
    for (final foto in [cedula, selfie]) {
      final error = validarFoto(foto);
      if (error != null) throw AppException(error);
    }
    await _repositorio.enviar(cedula: cedula, selfie: selfie);
  }
}
