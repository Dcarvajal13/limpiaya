import '../entities/perfil_publico.dart';

/// Contrato del perfil público de una trabajadora (HU-06): QUÉ se puede pedir,
/// sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_trabajadora_publica_repository.dart y lee las
/// vistas `trabajadoras_publicas` y `resenas_publicas`.
abstract interface class TrabajadoraPublicaRepository {
  /// Perfil de la trabajadora con sus reseñas visibles, o `null` si no existe
  /// o si la cuenta no es de trabajadora.
  ///
  /// Nunca trae teléfono ni correo: esos datos no están en la vista.
  Future<PerfilPublico?> perfil(String trabajadoraId);
}
