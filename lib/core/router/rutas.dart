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

  /// HU-13 · Mis servicios de la trabajadora (pestaña Postulaciones).
  static const misServicios = '/trabajadora/servicios';

  /// HU-45 · Detalle de una solicitud vista por la trabajadora. Nunca muestra
  /// la dirección exacta del cliente.
  static const detalleSolicitudPatron = '/trabajadora/solicitudes/:id';
  static String detalleSolicitud(String solicitudId) =>
      '/trabajadora/solicitudes/$solicitudId';

  /// HU-21 · Verificar mi identidad. HU-12 criterio 4 manda aquí cuando la
  /// trabajadora todavía no tiene la identidad aprobada.
  static const verificacionTrabajadora = '/trabajadora/verificacion';

  /// Detalle de un servicio agendado. Lo construye HU-16; mientras tanto la
  /// ruta existe para que HU-13 c3 pueda llevar hasta ahí.
  static const servicioAgendadoPatron = '/trabajadora/servicios/:id';
  static String servicioAgendado(String solicitudId) =>
      '$misServicios/$solicitudId';

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
