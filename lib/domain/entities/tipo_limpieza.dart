/// Tipo de limpieza de una solicitud (enum `tipo_limpieza` en la base).
enum TipoLimpieza {
  general('general', 'General'),
  profunda('profunda', 'Profunda'),
  postMudanza('post_mudanza', 'Post-mudanza'),
  planchado('planchado', 'Planchado');

  const TipoLimpieza(this.valorDb, this.etiqueta);

  /// Valor exacto con el que se guarda en Supabase.
  final String valorDb;

  /// Texto que ve la persona en pantalla.
  final String etiqueta;

  /// Nombre del servicio para títulos: "Limpieza profunda", "Planchado".
  String get servicio => switch (this) {
        TipoLimpieza.planchado => 'Planchado',
        _ => 'Limpieza ${etiqueta.toLowerCase()}',
      };

  static TipoLimpieza desdeDb(String valor) =>
      TipoLimpieza.values.firstWhere((tipo) => tipo.valorDb == valor);
}
