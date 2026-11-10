import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_publico.dart';
import '../../domain/repositories/busqueda_trabajadoras_repository.dart';
import '../../domain/services/busqueda_service.dart';
import '../models/perfil_publico_model.dart';

/// Implementación de BusquedaTrabajadorasRepository usando Supabase (HU-25).
///
/// Busca en la vista `trabajadoras_publicas` (sin teléfono, correo ni
/// dirección) e invita con la función `invitar_trabajadora`, que revisa que
/// la solicitud sea del cliente, esté Publicada y sea en una zona de ella.
class SupabaseBusquedaTrabajadorasRepository
    implements BusquedaTrabajadorasRepository {
  SupabaseBusquedaTrabajadorasRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<PerfilPublico>> buscar({int? zonaId}) async {
    try {
      var consulta = _client
          .from('trabajadoras_publicas')
          .select()
          .eq('verificada', true);
      // c1 · Solo las que trabajan en esa zona.
      if (zonaId != null) consulta = consulta.contains('zona_ids', [zonaId]);

      final filas = await consulta.limit(100);
      return [
        for (final fila in filas)
          PerfilPublicoModel.desdeJson(
            Map<String, dynamic>.from(fila),
            resenas: const [],
            fotoUrl: _fotoUrl(fila['foto_path'] as String?),
          ),
      ];
    } on Exception {
      throw const AppException(BusquedaService.mensajeError);
    }
  }

  @override
  Future<void> invitar({
    required String solicitudId,
    required String trabajadoraId,
  }) async {
    try {
      await _client.rpc(
        'invitar_trabajadora',
        params: {'p_solicitud': solicitudId, 'p_trabajadora': trabajadoraId},
      );
    } on PostgrestException catch (e) {
      throw AppException(BusquedaService.traducir(e.message));
    } on Exception {
      throw const AppException(BusquedaService.errorInvitar);
    }
  }

  String? _fotoUrl(String? fotoPath) => fotoPath == null
      ? null
      : _client.storage.from('avatars').getPublicUrl(fotoPath);
}
