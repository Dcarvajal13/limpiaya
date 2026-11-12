import '../entities/direccion_guardada.dart';

/// Contrato para las direcciones guardadas del cliente: QUÉ se puede pedir,
/// sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_direcciones_repository.dart.
abstract interface class DireccionesRepository {
  /// Mis direcciones, de la más antigua a la más nueva (la primera suele ser
  /// "Casa", la del perfil).
  Future<List<DireccionGuardada>> misDirecciones();

  /// Crea una dirección nueva, o edita la que tenga [id].
  Future<void> guardar({
    String? id,
    required String nombre,
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  });

  Future<void> eliminar(String id);
}
