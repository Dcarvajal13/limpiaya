import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/reputacion_repository.dart';

/// Implementación de ReputacionRepository usando Supabase.
class SupabaseReputacionRepository implements ReputacionRepository {
  SupabaseReputacionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<double?> miPromedio() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    try {
      final fila = await _client
          .from('reputacion')
          .select('promedio')
          .eq('usuario_id', usuario.id)
          .maybeSingle();
      return (fila?['promedio'] as num?)?.toDouble();
    } on Exception {
      // Si falla, la insignia simplemente sale sin estrellas.
      return null;
    }
  }
}
