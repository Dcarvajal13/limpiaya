import '../entities/perfil_publico.dart';

/// HU-25 · Contrato para buscar trabajadoras e invitarlas: QUÉ se puede
/// pedir, sin decir CÓMO.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_busqueda_trabajadoras_repository.dart.
abstract interface class BusquedaTrabajadorasRepository {
  /// Trabajadoras con la identidad verificada. Con [zonaId], solo las que
  /// trabajan en esa zona (c1). Sin reseñas: solo el resumen de su perfil.
  Future<List<PerfilPublico>> buscar({int? zonaId});

  /// c3 · Invita a una trabajadora a una solicitud Publicada del cliente.
  /// Ella la verá marcada como "Te invitaron".
  Future<void> invitar({
    required String solicitudId,
    required String trabajadoraId,
  });

  /// Invitaciones que hice: a qué trabajadora y en qué solicitud. Sirve para
  /// mostrar "Invitada" en vez de "Invitar".
  Future<List<({String solicitudId, String trabajadoraId})>> misInvitaciones();
}
