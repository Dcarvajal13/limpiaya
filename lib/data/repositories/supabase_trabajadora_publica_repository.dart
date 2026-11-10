import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_publico.dart';
import '../../domain/repositories/trabajadora_publica_repository.dart';
import '../models/perfil_publico_model.dart';

/// Implementación de TrabajadoraPublicaRepository usando Supabase.
///
/// Es la ÚNICA parte de la app que habla con Supabase para el perfil público.
/// Lee las vistas `trabajadoras_publicas` y `resenas_publicas`, que por diseño
/// no traen teléfono, correo ni dirección (HU-06 c3).
class SupabaseTrabajadoraPublicaRepository
    implements TrabajadoraPublicaRepository {
  SupabaseTrabajadoraPublicaRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PerfilPublico?> perfil(String trabajadoraId) async {
    try {
      final fila = await _client
          .from('trabajadoras_publicas')
          .select()
          .eq('id', trabajadoraId)
          .maybeSingle();
      if (fila == null) return null;

      // Las reseñas que ya se pueden mostrar (HU-29 c4). Si falla, el perfil
      // sale con "Aún no tiene reseñas" en vez de romperse entero.
      List<Map<String, dynamic>> resenas = const [];
      try {
        final filas = await _client
            .from('resenas_publicas')
            .select(
              'id, estrellas, comentario, autor_nombre, created_at, '
              'respuesta, respuesta_en',
            )
            .eq('destinatario_id', trabajadoraId)
            .order('created_at', ascending: false)
            .limit(20);
        resenas = [for (final r in filas) Map<String, dynamic>.from(r)];
      } on Exception {
        resenas = const [];
      }

      return PerfilPublicoModel.desdeJson(
        Map<String, dynamic>.from(fila),
        resenas: resenas,
        fotoUrl: _fotoUrl(fila['foto_path'] as String?),
      );
    } on Exception {
      throw const AppException('No pudimos cargar el perfil de la trabajadora.');
    }
  }

  String? _fotoUrl(String? fotoPath) => fotoPath == null
      ? null
      : _client.storage.from('avatars').getPublicUrl(fotoPath);
}
