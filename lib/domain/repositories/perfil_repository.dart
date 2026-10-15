import '../entities/perfil_trabajadora.dart';
import '../entities/tipo_limpieza.dart';
import '../entities/zona.dart';

/// Contrato del perfil de la trabajadora: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_perfil_repository.dart.
abstract interface class PerfilRepository {
  /// Catálogo de zonas de Caracas (tabla `zonas`), ordenadas por nombre.
  Future<List<Zona>> zonasDisponibles();

  /// Perfil de quien inició sesión.
  Future<PerfilTrabajadora> miPerfil();

  /// HU-04 · Guarda experiencia, tarifa, descripción, zonas y servicios.
  Future<void> guardarPerfil({
    required List<int> zonasIds,
    required List<TipoLimpieza> servicios,
    int? experienciaAnios,
    double? tarifaReferencia,
    String? descripcion,
  });

  /// Sube la foto al bucket `avatars` y devuelve su dirección pública.
  ///
  /// Lanza AppException si no es JPG/PNG o si pasa de 5 MB
  /// (HU-04, criterio 4); en ese caso la foto anterior no se toca.
  Future<String> subirFoto({
    required List<int> bytes,
    required String nombreArchivo,
  });
}
