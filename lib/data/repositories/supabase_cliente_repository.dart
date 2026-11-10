import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/perfil_cliente.dart';
import '../../domain/entities/zona.dart';
import '../../domain/repositories/cliente_repository.dart';

/// Implementación de ClienteRepository usando Supabase.
///
/// Es la ÚNICA parte de la app que habla con Supabase para el perfil del
/// cliente. La dirección exacta es privada: nunca sale de la tabla
/// `clientes` (las trabajadoras usan la vista `solicitudes_publicas`,
/// que no la incluye — HD-03, criterio 3).
class SupabaseClienteRepository implements ClienteRepository {
  SupabaseClienteRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('No pudimos identificar tu cuenta.');
    }
    return usuario.id;
  }

  @override
  Future<List<Zona>> zonasDisponibles() async {
    try {
      final filas = await _client.from('zonas').select().order('nombre');
      return [
        for (final fila in filas) Zona.desdeFila(fila),
      ];
    } on Exception {
      throw const AppException('No pudimos cargar las zonas.');
    }
  }

  @override
  Future<PerfilCliente> miPerfil() async {
    final uid = _uid;
    try {
      final fila = await _client
          .from('clientes')
          .select('zona_id, direccion, punto_referencia')
          .eq('id', uid)
          .maybeSingle();
      if (fila == null) return const PerfilCliente();

      final zonaId = fila['zona_id'] as int?;
      Zona? zona;
      if (zonaId != null) {
        final z = await _client
            .from('zonas')
            .select('id, nombre, municipio, parroquia')
            .eq('id', zonaId)
            .maybeSingle();
        if (z != null) zona = Zona.desdeFila(z);
      }

      return PerfilCliente(
        zona: zona,
        direccion: fila['direccion'] as String?,
        puntoReferencia: fila['punto_referencia'] as String?,
      );
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException('No pudimos cargar tu perfil.');
    }
  }

  @override
  Future<void> guardarPerfil({
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    final uid = _uid;
    try {
      // upsert: la fila puede no existir todavía (el perfil se completa
      // después de registrarse).
      await _client.from('clientes').upsert({
        'id': uid,
        'zona_id': zonaId,
        'direccion': direccion.trim(),
        'punto_referencia': puntoReferencia?.trim(),
      });
    } on Exception {
      throw const AppException('No pudimos guardar tu perfil. Intenta de nuevo.');
    }
  }
}
