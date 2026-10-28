import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/estado_postulacion.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/repositories/postulacion_repository.dart';
import '../models/postulacion_model.dart';

/// Implementación de PostulacionRepository usando Supabase.
///
/// Es la ÚNICA parte de la app que habla con Supabase para postulaciones.
class SupabasePostulacionRepository implements PostulacionRepository {
  SupabasePostulacionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Postulacion>> misPostulaciones() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      // RLS: la trabajadora solo lee sus propias postulaciones.
      // Las retiradas las decidió ella (HU-26): no se listan.
      final postulaciones = await _client
          .from('postulaciones')
          .select('id, solicitud_id, estado, created_at')
          .eq('trabajadora_id', usuario.id)
          .neq('estado', EstadoPostulacion.retirada.valorDb)
          .order('created_at', ascending: false);
      if (postulaciones.isEmpty) return const [];

      // La vista solicitudes_publicas incluye las solicitudes a las que me
      // postulé, aunque ya no estén Publicadas, y nunca trae la dirección.
      final filas = await _client
          .from('solicitudes_publicas')
          .select()
          .inFilter('id', [
        for (final p in postulaciones) p['solicitud_id'] as String,
      ]);
      final solicitudes = {
        for (final fila in filas)
          fila['id'] as String: Map<String, dynamic>.from(fila),
      };

      final clientes = await _clientes({
        for (final fila in solicitudes.values) fila['cliente_id'] as String,
      });

      return [
        for (final p in postulaciones)
          if (solicitudes[p['solicitud_id']] case final solicitud?)
            PostulacionModel.desdeJson(
              Map<String, dynamic>.from(p),
              solicitud,
              miId: usuario.id,
              clienteNombre:
                  clientes[solicitud['cliente_id']]?['nombre'] as String?,
              clienteFotoUrl: _fotoUrl(
                clientes[solicitud['cliente_id']]?['foto_path'] as String?,
              ),
            ),
      ];
    } on Exception {
      throw const AppException('No pudimos cargar tus postulaciones.');
    }
  }

  /// Nombre y foto de los clientes (vista `perfiles_publicos`). Es información
  /// complementaria: si falla, las tarjetas salen sin nombre en vez de romper.
  Future<Map<String, Map<String, dynamic>>> _clientes(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final filas = await _client
          .from('perfiles_publicos')
          .select('id, nombre, foto_path')
          .inFilter('id', ids.toList());
      return {
        for (final fila in filas)
          fila['id'] as String: Map<String, dynamic>.from(fila),
      };
    } on Exception {
      return const {};
    }
  }

  String? _fotoUrl(String? fotoPath) =>
      fotoPath == null
          ? null
          : _client.storage.from('avatars').getPublicUrl(fotoPath);
}
