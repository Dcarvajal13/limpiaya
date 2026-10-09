/// Direcciones (URLs) de las pantallas.
///
/// Siempre navegar con estas constantes, nunca con texto escrito a mano:
///   context.go(Rutas.registro);   ✅
///   context.go('/registro');      ❌
abstract final class Rutas {
  static const login = '/login';
  static const registro = '/registro';
  static const inicio = '/inicio';

  /// Pantallas que se pueden ver sin iniciar sesión.
  static const publicas = {login, registro};
}
