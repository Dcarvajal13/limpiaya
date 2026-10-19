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

  /// Dirección del perfil del cliente (HU-05).
  ///
  /// Misma regla que la base (`clientes.direccion`): entre 5 y 300
  /// caracteres. Si no coincide, PostgreSQL rechaza el guardado.
  static String? direccion(String? valor) {
    final vacio = requerido(valor);
    if (vacio != null) return vacio;
    final largo = valor!.trim().length;
    if (largo < 5) return 'Escribe al menos 5 caracteres';
    if (largo > 300) return 'Máximo 300 caracteres';
    return null;
  }

  /// Validación para campos opcionales con largo máximo (HU-05,
  /// punto de referencia: 200 caracteres en la base).
  static String? Function(String?) maximo(int caracteres) {
    return (valor) {
      if (valor == null || valor.trim().isEmpty) return null;
      if (valor.trim().length > caracteres) {
        return 'Máximo $caracteres caracteres';
      }
      return null;
    };
  }
}
