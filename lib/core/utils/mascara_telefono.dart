import 'package:flutter/services.dart';

/// Máscara del teléfono venezolano (taller UX, H5 · severidad 3).
///
/// La persona escribe solo números y el guion aparece solo:
/// "04141234567" → "0414-1234567". Así ya no recibe el error de formato por
/// escribir el número sin guion. Ignora espacios, puntos y paréntesis, y
/// corta en 11 dígitos.
class MascaraTelefono extends TextInputFormatter {
  const MascaraTelefono();

  static const _digitos = 11;

  /// "0414 123.45.67" → "0414-1234567". También sirve fuera de los campos.
  static String formatear(String texto) {
    var numeros = texto.replaceAll(RegExp(r'\D'), '');
    if (numeros.length > _digitos) numeros = numeros.substring(0, _digitos);
    if (numeros.length <= 4) return numeros;
    return '${numeros.substring(0, 4)}-${numeros.substring(4)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = formatear(newValue.text);
    return TextEditingValue(
      text: texto,
      // El cursor siempre al final: el número se escribe de corrido.
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
