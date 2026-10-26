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

  /// Reparte a cada quien a su inicio según su rol. Mientras se carga el
  /// rol, muestra una espera.
  static const inicio = '/inicio';

  /// Inicio de cada rol (HU-02A / HU-02B). Todo lo que empiece por estas
  /// direcciones solo lo puede abrir ese rol, por ejemplo '/cliente/publicar'.
  static const inicioCliente = '/cliente';
  static const inicioTrabajadora = '/trabajadora';
  static const inicioAdmin = '/admin';


  /// HU-07 · Publicar una solicitud. Va dentro de /cliente, así que solo la
  /// puede abrir un cliente.
  static const publicarSolicitud = '/cliente/publicar';
  /// Perfil de la trabajadora (HU-04). Antes de ver solicitudes, la
  /// trabajadora recién registrada completa su perfil.
  static const perfilTrabajadora = '/trabajadora/perfil';

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
