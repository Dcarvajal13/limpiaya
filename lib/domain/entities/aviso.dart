/// HU-50 · Un aviso en la campana de la app.
///
/// Sale de la tabla `avisos`. No depende de Supabase.
enum TipoAviso {
  postulacion('Postulación'),
  eleccion('Elección'),
  cancelacion('Cancelación'),
  completada('Completado'),
  recordatorio('Recordatorio'),
  cuenta('Cuenta'),
  sistema('Aviso');

  const TipoAviso(this.etiqueta);
  final String etiqueta;

  static TipoAviso desdeTexto(String? valor) => switch (valor) {
        'postulacion' => TipoAviso.postulacion,
        'eleccion' => TipoAviso.eleccion,
        'cancelacion' => TipoAviso.cancelacion,
        'completada' => TipoAviso.completada,
        'recordatorio' => TipoAviso.recordatorio,
        'cuenta' => TipoAviso.cuenta,
        _ => TipoAviso.sistema,
      };
}

class Aviso {
  const Aviso({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.creadoEn,
    this.ruta,
    this.leidoEn,
  });

  final String id;
  final TipoAviso tipo;
  final String titulo;
  final String mensaje;

  /// Ruta interna a la que navegar al tocar el aviso (opcional).
  final String? ruta;

  final DateTime creadoEn;

  /// Null mientras la persona no lo haya abierto o marcado como leído.
  final DateTime? leidoEn;

  bool get leido => leidoEn != null;
}
