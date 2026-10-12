/// Direcciones (URLs) de las pantallas.
///
/// Siempre navegar con estas constantes, nunca con texto escrito a mano:
///   context.go(Rutas.registro);   ✅
///   context.go('/registro');      ❌
abstract final class Rutas {
  /// Página de inicio para visitantes (HU-62). Es lo primero que se ve.
  static const landing = '/';
  static const login = '/login';
  static const registro = '/registro';
  static const inicio = '/inicio';
  static const sistemaDiseno = '/diseno';

  /// Registro con el rol ya sugerido, desde los botones de la landing.
  /// TODO(HU-01): leer `rol` de la URL y dejar marcada esa opción.
  static const registroCliente = '$registro?rol=cliente';
  static const registroTrabajadora = '$registro?rol=trabajadora';

  /// Pantallas que se pueden ver sin iniciar sesión.
  /// Si alguien con sesión entra a una de estas, se le manda a su inicio
  /// (HU-62, criterio 4).
  static const publicas = {landing, login, registro};

  /// Pantallas que se ven igual con o sin sesión (nunca redirigen).
  static const libres = {sistemaDiseno};
}
