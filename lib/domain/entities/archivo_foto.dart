/// Foto elegida por la persona, lista para subir (HU-21).
class ArchivoFoto {
  const ArchivoFoto({required this.bytes, required this.nombre});

  final List<int> bytes;

  /// Nombre original del archivo, por ejemplo "cedula.jpg".
  final String nombre;

  String get _minusculas => nombre.toLowerCase();

  bool get esPng => _minusculas.endsWith('.png');

  bool get esJpg =>
      _minusculas.endsWith('.jpg') || _minusculas.endsWith('.jpeg');
}
