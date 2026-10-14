import '../entities/perfil_cliente.dart';
import '../entities/zona.dart';

/// Contrato del perfil del cliente: QUÉ se puede pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_cliente_repository.dart.
abstract interface class ClienteRepository {
  /// Catálogo de zonas de Caracas (tabla `zonas`), ordenadas por nombre.
  Future<List<Zona>> zonasDisponibles();

  /// Perfil de quien inició sesión.
  Future<PerfilCliente> miPerfil();

  /// HU-05 · Guarda la zona y la dirección de referencia.
  Future<void> guardarPerfil({
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  });
}
