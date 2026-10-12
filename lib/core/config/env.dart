/// Lee las claves de Supabase que vienen de env.json.
///
/// env.json NO está en el repositorio (ver .gitignore). Cada integrante
/// tiene su copia local. Se pasa al correr la app con:
///   --dart-define-from-file=env.json
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Detiene la app con un mensaje claro si faltan las claves.
  static void validar() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'Faltan las claves de Supabase. Revisa que exista env.json y corre: '
        'flutter run -d chrome --dart-define-from-file=env.json',
      );
    }
  }
}
