import '../entities/estado_solicitud.dart';
import '../entities/orden_trabajadoras.dart';
import '../entities/perfil_publico.dart';
import '../entities/solicitud.dart';

/// Reglas de HU-25 · Buscar trabajadoras e invitarlas.
///
/// Vive en el dominio y no conoce Supabase ni Flutter.
abstract final class BusquedaService {
  /// c4 · Sin resultados.
  static const sinResultados = 'No hay trabajadoras con esos filtros';

  static const mensajeError = 'No pudimos cargar las trabajadoras.';

  static const errorInvitar =
      'No pudimos enviar la invitación. Intenta de nuevo.';

  /// Mensajes de la función `invitar_trabajadora` que se muestran tal cual.
  static const _mensajesDeLaBase = [
    'Ya la invitaste a esta solicitud',
    'Ella ya se postuló a esta solicitud',
    'Ella no trabaja en la zona de esta solicitud',
    'Solo puedes invitar a una solicitud publicada',
    'No encontramos esa solicitud',
    'No encontramos a esa trabajadora',
  ];

  /// Mensaje de la base → mensaje para el cliente.
  static String traducir(String mensaje) {
    for (final conocido in _mensajesDeLaBase) {
      if (mensaje.contains(conocido)) return conocido;
    }
    return errorInvitar;
  }

  /// c3 · Confirmación: "Invitaste a Carmen. Verá tu solicitud marcada como
  /// «Te invitaron»."
  static String invitada(String nombre) =>
      'Invitaste a ${nombre.trim().split(RegExp(r'\s+')).first}. Verá tu '
      'solicitud marcada como «Te invitaron».';

  /// c2 · Ordena sin cambiar la lista original.
  ///
  /// - Calificación: de mayor a menor promedio; las que no tienen reseñas
  ///   van al final. En un empate, primero la destacada (HU-61) y luego la
  ///   que tiene más servicios.
  /// - Servicios: de más a menos servicios completados; en un empate, el
  ///   mejor promedio.
  static List<PerfilPublico> ordenar(
    List<PerfilPublico> trabajadoras,
    OrdenTrabajadoras orden,
  ) {
    int porNombre(PerfilPublico a, PerfilPublico b) =>
        a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    int porPromedio(PerfilPublico a, PerfilPublico b) =>
        (b.promedio ?? -1).compareTo(a.promedio ?? -1);
    int porServicios(PerfilPublico a, PerfilPublico b) =>
        b.serviciosCompletados.compareTo(a.serviciosCompletados);
    int porDestacada(PerfilPublico a, PerfilPublico b) =>
        (b.destacada ? 1 : 0).compareTo(a.destacada ? 1 : 0);

    final criterios = switch (orden) {
      OrdenTrabajadoras.calificacion => [
          porPromedio,
          porDestacada,
          porServicios,
          porNombre,
        ],
      OrdenTrabajadoras.servicios => [
          porServicios,
          porPromedio,
          porDestacada,
          porNombre,
        ],
    };

    return [...trabajadoras]..sort((a, b) {
        for (final criterio in criterios) {
          final r = criterio(a, b);
          if (r != 0) return r;
        }
        return 0;
      });
  }

  /// c3 · Solicitudes a las que se puede invitar a esa trabajadora:
  /// Publicadas, futuras y en una zona donde ella trabaja.
  static List<Solicitud> solicitudesParaInvitar(
    List<Solicitud> misSolicitudes,
    PerfilPublico trabajadora, {
    DateTime? ahora,
  }) {
    final momento = ahora ?? DateTime.now();
    return [
      for (final s in publicadas(misSolicitudes, ahora: momento))
        if (trabajadora.zonaIds.contains(s.zonaId)) s,
    ];
  }

  /// Solicitudes Publicadas y futuras del cliente.
  static List<Solicitud> publicadas(
    List<Solicitud> misSolicitudes, {
    DateTime? ahora,
  }) {
    final momento = ahora ?? DateTime.now();
    return [
      for (final s in misSolicitudes)
        if (s.estado == EstadoSolicitud.publicada && s.inicio.isAfter(momento))
          s,
    ];
  }
}
