/// Direcciones (URLs) de las pantallas.
///
/// Siempre navegar con estas constantes, nunca con texto escrito a mano:
///   context.go(Rutas.registro);   ✅
///   context.go('/registro');      ❌
abstract final class Rutas {
  static const login = '/login';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const sistemaDiseno = '/diseno';

  /// Pantallas que se pueden ver sin iniciar sesión.
  /// Si alguien con sesión entra a una de estas, se le manda a su inicio.
  static const publicas = {login, registro};

  /// Pantallas que se ven igual con o sin sesión (nunca redirigen).
  static const libres = {sistemaDiseno};
}
