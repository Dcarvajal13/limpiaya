import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_cliente_publico.dart';
import '../../domain/repositories/cliente_publico_repository.dart';
import '../models/perfil_publico_model.dart';

/// Implementación de ClientePublicoRepository usando Supabase (HU-46).
///
/// Solo lee vistas públicas: `perfiles_publicos` (nombre y foto),
/// `reputacion` (promedio y servicios) y `resenas_publicas` (las reseñas ya
/// visibles). Ninguna trae teléfono, correo ni dirección.
class SupabaseClientePublicoRepository implements ClientePublicoRepository {
  SupabaseClientePublicoRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PerfilClientePublico?> perfil(String clienteId) async {
    try {
      final perfil = await _client
          .from('perfiles_publicos')
          .select('id, rol, nombre, foto_path')
          .eq('id', clienteId)
          .maybeSingle();
      if (perfil == null || perfil['rol'] != 'cliente') return null;

      final reputacion = await _client
          .from('reputacion')
          .select('promedio, total_resenas, servicios_completados')
          .eq('usuario_id', clienteId)
          .maybeSingle();

      // Complementario: si fallan las reseñas, el perfil sale igual.
      List<Map<String, dynamic>> resenas = const [];
      try {
        final filas = await _client
            .from('resenas_publicas')
            .select(
              'id, estrellas, comentario, autor_nombre, created_at, '
              'respuesta, respuesta_en',
            )
            .eq('destinatario_id', clienteId)
            .order('created_at', ascending: false)
            .limit(20);
        resenas = [for (final r in filas) Map<String, dynamic>.from(r)];
      } on Exception {
        resenas = const [];
      }

      final fotoPath = perfil['foto_path'] as String?;
      return PerfilClientePublico(
        id: perfil['id'] as String,
        nombre: perfil['nombre'] as String,
        fotoUrl: fotoPath == null
            ? null
            : _client.storage.from('avatars').getPublicUrl(fotoPath),
        promedio: (reputacion?['promedio'] as num?)?.toDouble(),
        totalResenas: (reputacion?['total_resenas'] as num?)?.toInt() ?? 0,
        serviciosCompletados:
            (reputacion?['servicios_completados'] as num?)?.toInt() ?? 0,
        resenas: [
          for (final resena in resenas)
            PerfilPublicoModel.resenaDesdeJson(resena),
        ],
      );
    } on Exception {
      throw const AppException('No pudimos cargar el perfil del cliente.');
    }
  }
}
