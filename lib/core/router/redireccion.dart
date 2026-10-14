import '../../domain/entities/rol_usuario.dart';
import 'rutas.dart';

/// Reglas de a dónde puede entrar cada quien. Las usa el router.
///
/// Es una función sin Flutter ni Supabase para poder probarla fácil
/// (test/core/router/redireccion_test.dart).
///
/// Devuelve la dirección a la que hay que mandar a la persona,
/// o null si puede quedarse donde está.
String? redirigir({
  required String ubicacion,
  required bool haySesion,
  required RolUsuario? rol,
  bool perfilCompleto = true,
}) {
  if (Rutas.libres.contains(ubicacion)) return null;

  final esPublica = Rutas.publicas.contains(ubicacion);

  // Sin sesión: solo landing, login y registro (HU-03, criterio 2).
  if (!haySesion) return esPublica ? null : Rutas.login;

  // HU-04, criterio 1: la trabajadora recién registrada completa su perfil
  // antes de ver las solicitudes. Se revisa ANTES de mandarla a su inicio,
  // porque go_router evalúa la redirección una sola vez por navegación: si
  // primero la mandáramos a /trabajadora, se quedaría ahí.
  if (rol == RolUsuario.trabajadora &&
      !perfilCompleto &&
      (ubicacion == Rutas.inicio || ubicacion == Rutas.inicioTrabajadora)) {
    return Rutas.perfilTrabajadora;
  }

  // Con sesión: la landing, el login y el registro mandan a su inicio
  // (HU-62 c4, HU-02A, HU-02B). Si el rol aún no carga, a la espera.
  final inicio = inicioDe(rol);
  if (esPublica || ubicacion == Rutas.inicio) {
    return ubicacion == inicio ? null : inicio;
  }

  // Una pantalla de otro rol (una trabajadora abriendo '/cliente'...).
  return puedeVer(ubicacion, rol) ? null : inicio;
}

/// Pantalla de inicio de cada rol.
String inicioDe(RolUsuario? rol) => switch (rol) {
      RolUsuario.cliente => Rutas.inicioCliente,
      RolUsuario.trabajadora => Rutas.inicioTrabajadora,
      RolUsuario.admin => Rutas.inicioAdmin,
      null => Rutas.inicio,
    };

/// Si ese rol puede abrir esa dirección.
bool puedeVer(String ubicacion, RolUsuario? rol) {
  bool esDe(String base) => ubicacion == base || ubicacion.startsWith('$base/');

  if (esDe(Rutas.inicioCliente)) return rol == RolUsuario.cliente;
  if (esDe(Rutas.inicioTrabajadora)) return rol == RolUsuario.trabajadora;
  if (esDe(Rutas.inicioAdmin)) return rol == RolUsuario.admin;
  return true;
}
