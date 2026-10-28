import 'estado_solicitud.dart';

/// Estado de una postulación (enum `estado_postulacion` en Supabase).
enum EstadoPostulacion {
  pendiente('pendiente', 'Pendiente'),
  aceptada('aceptada', 'Aceptada'),
  noSeleccionada('no_seleccionada', 'No seleccionada'),
  retirada('retirada', 'Retirada'),
  solicitudCancelada('solicitud_cancelada', 'Solicitud cancelada');

  const EstadoPostulacion(this.valorDb, this.etiqueta);

  /// Valor exacto en la base de datos Postgres.
  final String valorDb;

  /// Texto mostrado al usuario.
  final String etiqueta;

  static EstadoPostulacion desdeDb(String valor) =>
      EstadoPostulacion.values.firstWhere(
        (e) => e.valorDb == valor,
        orElse: () => EstadoPostulacion.pendiente,
      );

  /// HU-13 · Estado que la trabajadora debe ver.
  ///
  /// La base guarda el estado de la postulación, pero los cambios de estado
  /// (elegir trabajadora, cancelar solicitud) los hará HD-04 con funciones de
  /// Postgres. Mientras tanto, y para que la pantalla nunca muestre algo
  /// desactualizado, el estado se deduce también de la solicitud:
  ///
  /// - Solicitud cancelada → "Solicitud cancelada" (c1).
  /// - Solicitud asignada o completada a OTRA trabajadora → "No seleccionada"
  ///   (c2), aunque la postulación siga como pendiente en la base.
  /// - Solicitud asignada a mí → "Aceptada".
  /// - Si no, se respeta el estado guardado.
  static EstadoPostulacion resolver({
    required EstadoPostulacion guardado,
    required EstadoSolicitud estadoSolicitud,
    required String? trabajadoraAsignadaId,
    required String miId,
  }) {
    // Retirada es decisión de la propia trabajadora: nada la cambia.
    if (guardado == EstadoPostulacion.retirada) return guardado;

    if (estadoSolicitud == EstadoSolicitud.cancelada) {
      return EstadoPostulacion.solicitudCancelada;
    }

    final haySeleccion = estadoSolicitud == EstadoSolicitud.asignada ||
        estadoSolicitud == EstadoSolicitud.completada;
    if (haySeleccion && trabajadoraAsignadaId != null) {
      return trabajadoraAsignadaId == miId
          ? EstadoPostulacion.aceptada
          : EstadoPostulacion.noSeleccionada;
    }

    return guardado;
  }
}
