/// Quién lleva los productos de limpieza (enum `quien_pone_productos` en la base).
enum QuienPoneProductos {
  cliente('cliente', 'Yo'),
  trabajadora('trabajadora', 'La trabajadora');

  const QuienPoneProductos(this.valorDb, this.etiqueta);

  /// Valor exacto con el que se guarda en Supabase.
  final String valorDb;

  /// Texto que ve la persona en pantalla.
  final String etiqueta;
}