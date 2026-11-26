import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/aviso.dart';
import '../../domain/entities/correo_aviso.dart';
import '../../domain/repositories/aviso_repository.dart';

/// Implementación Supabase de [AvisoRepository] (HU-50 y HU-49).
class SupabaseAvisoRepository implements AvisoRepository {
  SupabaseAvisoRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<List<Aviso>> misAvisos() async {
    final uid = _uid;
    if (uid == null) return const [];
    try {
      final filas = await _client
          .from('avisos')
          .select()
          .eq('usuario_id', uid)
          .order('created_at', ascending: false)
          .limit(50);
      return filas
          .map((f) => _aAviso(Map<String, dynamic>.from(f)))
          .toList();
    } on PostgrestException {
      throw const AppException('No pudimos cargar tus avisos.');
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Stream<List<Aviso>> streamAvisos() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _client
        .from('avisos')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', uid)
        .order('created_at', ascending: false)
        .map(
          (filas) => filas
              .map((f) => _aAviso(Map<String, dynamic>.from(f)))
              .toList(),
        );
  }

  @override
  Future<void> marcarLeido(String avisoId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client
          .from('avisos')
          .update({'leido_en': DateTime.now().toUtc().toIso8601String()})
          .eq('id', avisoId)
          .eq('usuario_id', uid)
          .isFilter('leido_en', null);
    } on Exception {
      // Si falla silenciosamente, se reintentará al abrir de nuevo.
    }
  }

  @override
  Future<void> marcarTodosLeidos() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _client
          .from('avisos')
          .update({'leido_en': DateTime.now().toUtc().toIso8601String()})
          .eq('usuario_id', uid)
          .isFilter('leido_en', null);
    } on PostgrestException {
      throw const AppException('No pudimos marcar los avisos como leídos.');
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<List<CorreoAviso>> misCorreos() async {
    final uid = _uid;
    if (uid == null) return const [];
    try {
      final filas = await _client
          .from('cola_correos')
          .select()
          .eq('usuario_id', uid)
          .order('created_at', ascending: false)
          .limit(40);
      return filas
          .map((f) => _aCorreo(Map<String, dynamic>.from(f)))
          .toList();
    } on PostgrestException {
      throw const AppException('No pudimos cargar tus avisos por correo.');
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<void> actualizarAvisosCorreo(bool activo) async {
    try {
      await _client.rpc(
        'actualizar_avisos_correo',
        params: {'p_activo': activo},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty
            ? e.message
            : 'No pudimos actualizar tu preferencia de correos.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  Aviso _aAviso(Map<String, dynamic> fila) => Aviso(
        id: fila['id'] as String,
        tipo: TipoAviso.desdeTexto(fila['tipo'] as String?),
        titulo: fila['titulo'] as String? ?? 'Aviso',
        mensaje: fila['mensaje'] as String? ?? '',
        ruta: fila['ruta'] as String?,
        creadoEn: DateTime.parse(fila['created_at'] as String).toLocal(),
        leidoEn: fila['leido_en'] == null
            ? null
            : DateTime.parse(fila['leido_en'] as String).toLocal(),
      );

  CorreoAviso _aCorreo(Map<String, dynamic> fila) => CorreoAviso(
        id: fila['id'] as String,
        tipo: TipoCorreoAviso.desdeTexto(fila['tipo'] as String?),
        asunto: fila['asunto'] as String? ?? '',
        cuerpo: fila['cuerpo'] as String? ?? '',
        estado: EstadoCorreoAviso.desdeTexto(fila['estado'] as String?),
        programadoPara:
            DateTime.parse(fila['programado_para'] as String).toLocal(),
        enviadoEn: fila['enviado_en'] == null
            ? null
            : DateTime.parse(fila['enviado_en'] as String).toLocal(),
        creadoEn: DateTime.parse(fila['created_at'] as String).toLocal(),
      );
}
