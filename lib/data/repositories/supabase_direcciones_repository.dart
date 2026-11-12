import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/direccion_guardada.dart';
import '../../domain/repositories/direcciones_repository.dart';
import '../../domain/services/direcciones_service.dart';

/// Implementación de DireccionesRepository usando Supabase.
///
/// Usa la tabla `direcciones_cliente`. La RLS deja a cada cliente ver y
/// cambiar solo las suyas, y la base pone sola el `cliente_id`.
class SupabaseDireccionesRepository implements DireccionesRepository {
  SupabaseDireccionesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<DireccionGuardada>> misDirecciones() async {
    try {
      final filas = await _client
          .from('direcciones_cliente')
          .select(
            'id, nombre, zona_id, direccion, punto_referencia, '
            'zonas(nombre)',
          )
          .order('created_at');
      return [
        for (final fila in filas)
          DireccionGuardada(
            id: fila['id'] as String,
            nombre: fila['nombre'] as String,
            zonaId: fila['zona_id'] as int,
            zona: (fila['zonas'] as Map?)?['nombre'] as String?,
            direccion: fila['direccion'] as String,
            puntoReferencia: fila['punto_referencia'] as String?,
          ),
      ];
    } on Exception {
      throw const AppException(DireccionesService.errorCargar);
    }
  }

  @override
  Future<void> guardar({
    String? id,
    required String nombre,
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    final referencia = puntoReferencia?.trim();
    final datos = {
      'nombre': nombre.trim(),
      'zona_id': zonaId,
      'direccion': direccion.trim(),
      'punto_referencia':
          (referencia == null || referencia.isEmpty) ? null : referencia,
    };
    try {
      if (id == null) {
        await _client.from('direcciones_cliente').insert(datos);
      } else {
        await _client.from('direcciones_cliente').update(datos).eq('id', id);
      }
    } on PostgrestException catch (e) {
      throw AppException(DireccionesService.traducir(e.message));
    } on Exception {
      throw const AppException(DireccionesService.errorGuardar);
    }
  }

  @override
  Future<void> eliminar(String id) async {
    try {
      await _client.from('direcciones_cliente').delete().eq('id', id);
    } on Exception {
      throw const AppException(DireccionesService.errorEliminar);
    }
  }
}
