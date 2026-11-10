import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/conversacion.dart';
import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/mensaje.dart';
import '../../domain/entities/tipo_limpieza.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_service.dart';
import '../models/mensaje_model.dart';

/// Implementación del chat con Supabase (HU-38).
///
/// Todo pasa por la tabla `mensajes`: RLS solo deja leerla a las dos partes
/// del servicio y solo deja escribir mientras `chat_abierto()` sea verdad.
/// La lectura en vivo usa la publicación de Realtime que ya trae la
/// migración de seguridad.
class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._client);

  final SupabaseClient _client;

  String get _usuarioId {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return usuario.id;
  }

  @override
  Future<List<Conversacion>> conversaciones() async {
    final yo = _usuarioId;
    try {
      // RLS devuelve solo mis servicios: los publicados por mí como cliente
      // o aquellos donde estoy asignada como trabajadora.
      final filas = await _client
          .from('solicitudes')
          .select('id, cliente_id, trabajadora_id, estado, tipo, inicio')
          .or('cliente_id.eq.$yo,trabajadora_id.eq.$yo')
          .inFilter('estado', ['asignada', 'completada', 'cancelada'])
          .order('inicio', ascending: false);
      if (filas.isEmpty) return const [];

      final servicios = [
        for (final fila in filas) Map<String, dynamic>.from(fila),
      ];
      final ids = [for (final fila in servicios) fila['id'] as String];

      final mensajes = await _client
          .from('mensajes')
          .select('solicitud_id, autor_id, contenido, created_at, leido_en')
          .inFilter('solicitud_id', ids)
          .order('created_at', ascending: true);

      // Último mensaje y no leídos de cada servicio.
      final ultimo = <String, Map<String, dynamic>>{};
      final noLeidos = <String, int>{};
      for (final fila in mensajes) {
        final datos = Map<String, dynamic>.from(fila);
        final solicitudId = datos['solicitud_id'] as String;
        ultimo[solicitudId] = datos;
        if (datos['autor_id'] != yo && datos['leido_en'] == null) {
          noLeidos[solicitudId] = (noLeidos[solicitudId] ?? 0) + 1;
        }
      }

      final conMensajes = servicios
          .where((fila) => ultimo.containsKey(fila['id']))
          .toList();
      if (conMensajes.isEmpty) return const [];

      final contrapartes = {
        for (final fila in conMensajes)
          (fila['cliente_id'] == yo
              ? fila['trabajadora_id']
              : fila['cliente_id']) as String,
      };
      final perfiles = await _perfiles(contrapartes);

      return [
        for (final fila in conMensajes)
          _conversacion(
            fila,
            yo,
            ultimo[fila['id']]!,
            noLeidos[fila['id']] ?? 0,
            perfiles,
          ),
      ];
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException('No pudimos cargar tus mensajes.');
    }
  }

  Conversacion _conversacion(
    Map<String, dynamic> fila,
    String yo,
    Map<String, dynamic> ultimo,
    int noLeidos,
    Map<String, Map<String, dynamic>> perfiles,
  ) {
    final soyCliente = fila['cliente_id'] == yo;
    final contraparteId =
        (soyCliente ? fila['trabajadora_id'] : fila['cliente_id']) as String;
    final perfil = perfiles[contraparteId];

    return Conversacion(
      solicitudId: fila['id'] as String,
      contraparteId: contraparteId,
      contraparteNombre: perfil?['nombre'] as String? ?? 'Sin nombre',
      contraparteFotoUrl: _fotoUrl(perfil?['foto_path'] as String?),
      tipo: TipoLimpieza.desdeDb(fila['tipo'] as String),
      inicio: DateTime.parse(fila['inicio'] as String).toLocal(),
      estado: EstadoSolicitud.desdeDb(fila['estado'] as String),
      ultimoMensaje: ultimo['contenido'] as String?,
      ultimoEn: DateTime.parse(ultimo['created_at'] as String).toLocal(),
      ultimoEsMio: ultimo['autor_id'] == yo,
      noLeidos: noLeidos,
    );
  }

  @override
  Stream<List<Mensaje>> mensajes(String solicitudId) {
    return _client
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('solicitud_id', solicitudId)
        // El stream ordena descendente si no se dice lo contrario.
        .order('created_at', ascending: true)
        .map((filas) => [for (final fila in filas) MensajeModel.desdeJson(fila)]);
  }

  @override
  Future<void> enviar(String solicitudId, String contenido) async {
    final yo = _usuarioId;
    try {
      await _client.from('mensajes').insert({
        'solicitud_id': solicitudId,
        'autor_id': yo,
        'contenido': contenido.trim(),
      });
    } on PostgrestException catch (e) {
      final cerrado = e.code == '42501' ||
          e.message.toLowerCase().contains('row-level security');
      throw AppException(
        cerrado ? ChatService.mensajeCerrado : ChatService.mensajeError,
      );
    } on Exception {
      throw const AppException(ChatService.mensajeError);
    }
  }

  @override
  Future<void> marcarLeidos(String solicitudId) async {
    final yo = _usuarioId;
    try {
      await _client
          .from('mensajes')
          .update({'leido_en': DateTime.now().toUtc().toIso8601String()})
          .eq('solicitud_id', solicitudId)
          .neq('autor_id', yo)
          .isFilter('leido_en', null);
    } on Exception {
      // No es grave: el aviso se queda hasta el próximo intento.
    }
  }

  /// Nombre y foto de cada persona por id (nunca teléfono ni correo).
  Future<Map<String, Map<String, dynamic>>> _perfiles(Set<String> ids) async {
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

  String? _fotoUrl(String? fotoPath) => fotoPath == null || fotoPath.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(fotoPath);
}
