/// Utilidades de texto.
abstract final class Texto {
  /// Iniciales para el avatar: "María Alejandra Rodríguez" → "MA".
  static String iniciales(String nombre) {
    final letras = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => String.fromCharCode(parte.runes.first).toUpperCase())
        .join();
    return letras.isEmpty ? '?' : letras;
  }
}
