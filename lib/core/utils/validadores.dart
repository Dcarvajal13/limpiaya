import '../constants/app_constants.dart';

/// Validaciones de formularios que se repiten en varias pantallas.
///
/// Cada función devuelve `null` si el valor es válido, o el mensaje de
/// error si no lo es. Así se pueden usar directo en un TextFormField:
///   TextFormField(validator: Validadores.email)
abstract final class Validadores {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _telefono = RegExp(r'^04\d{2}-\d{7}$');

  static String? requerido(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String? email(String? valor) {
    final vacio = requerido(valor);
    if (vacio != null) return vacio;
    if (!_email.hasMatch(valor!.trim())) return 'Correo inválido';
    return null;
  }

  /// Formato venezolano 04XX-XXXXXXX (HU-01, criterio 3).
  static String? telefono(String? valor) {
    final vacio = requerido(valor);
    if (vacio != null) return vacio;
    if (!_telefono.hasMatch(valor!.trim())) return 'Formato: 04XX-XXXXXXX';
    return null;
  }

  /// Mínimo 8 caracteres (HU-01, criterio 4).
  static String? password(String? valor) {
    if (valor == null || valor.length < AppConstants.largoMinimoPassword) {
      return 'Mínimo ${AppConstants.largoMinimoPassword} caracteres';
    }
    return null;
  }

  /// Tarifa por hora de referencia: opcional. Si se escribe, debe ser un
  /// número (HU-04, criterio 5).
  static String? tarifa(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    final numero = double.tryParse(texto.replaceAll(',', '.'));
    if (numero == null || numero < 0) return 'Escribe un número';
    return null;
  }

  /// Años de experiencia: opcional (0 es recién empezada). Si se escribe,
  /// entre 0 y 70.
  static String? anosExperiencia(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    final numero = int.tryParse(texto);
    if (numero == null || numero < 0 || numero > 70) return 'Escribe los años (0 a 70)';
    return null;
  }
}
