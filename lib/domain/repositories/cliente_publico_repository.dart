import '../entities/perfil_cliente_publico.dart';

/// HU-46 · Contrato para ver la reputación de un cliente: QUÉ se puede pedir,
/// sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_cliente_publico_repository.dart.
abstract interface class ClientePublicoRepository {
  /// Nombre, foto, promedio, servicios completados y reseñas del cliente, o
  /// `null` si la cuenta no existe o no es de cliente.
  Future<PerfilClientePublico?> perfil(String clienteId);
}
