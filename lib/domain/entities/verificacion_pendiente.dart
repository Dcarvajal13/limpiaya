/// HU-33 · Verificación de identidad que espera la revisión del administrador.
///
/// Junta lo que el admin necesita para decidir: los datos de la cuenta de la
/// trabajadora y las dos fotos que envió en HU-21 (cédula y selfie).
class VerificacionPendiente {
  const VerificacionPendiente({
    required this.id,
    required this.trabajadoraId,
    required this.nombre,
    required this.enviada,
    required this.cuentaCreada,
    this.telefono,
    this.fotoUrl,
    this.cedulaUrl,
    this.selfieUrl,
  });

  final String id;
  final String trabajadoraId;
  final String nombre;
  final String? telefono;

  /// Foto de perfil (bucket público "avatars"), si tiene.
  final String? fotoUrl;

  /// Links temporales a las fotos privadas del bucket "verificaciones".
  /// Son nulos si no se pudieron generar (por ejemplo, si falta el archivo).
  final String? cedulaUrl;
  final String? selfieUrl;

  /// Cuándo la trabajadora envió sus documentos (orden de la cola, HU-33 c1).
  final DateTime enviada;

  /// Cuándo se creó la cuenta.
  final DateTime cuentaCreada;
}
