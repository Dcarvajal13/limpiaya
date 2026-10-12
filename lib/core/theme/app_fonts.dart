import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografías del prototipo:
/// - Títulos: Bricolage Grotesque
/// - Texto: Figtree
///
/// Si por algún motivo la fuente no carga, se usa la del sistema
/// y la app sigue funcionando.
abstract final class AppFonts {
  static const familiaTitulos = 'Bricolage Grotesque';
  static const familiaTexto = 'Figtree';

  static TextStyle titulos(TextStyle base) => _fuente(familiaTitulos, base);

  static TextStyle texto(TextStyle base) => _fuente(familiaTexto, base);

  static TextStyle _fuente(String familia, TextStyle base) {
    try {
      return GoogleFonts.getFont(familia, textStyle: base);
    } catch (_) {
      return base;
    }
  }
}
