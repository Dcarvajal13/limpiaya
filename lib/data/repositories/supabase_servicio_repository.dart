import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/servicio_agendado.dart';
import '../../domain/repositories/servicio_repository.dart';
import '../../domain/services/servicio_service.dart';
import '../models/servicio_agendado_model.dart';

/// Implementación de ServicioRepository usando Supabase.
///
/// Cada acción llama a una función de Postgres (migraciones de HU-15 en
/// adelante) que revisa los permisos y cambia los estados en un solo paso.
/// Para leer (HU-16) se consulta la tabla `solicitudes`: RLS solo devuelve
/// las del cliente dueño o la trabajadora asignada, con su dirección.
class SupabaseServicioRepository implements ServicioRepository {
  SupabaseServicioRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> elegir(String postulacionId) async {
    try {
      await _client.rpc(
        'elegir_trabajadora',
        params: {'p_postulacion': postulacionId},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        ServicioService.traducir(
          e.message,
          ServicioService.mensajesElegir,
          ServicioService.mensajeErrorElegir,
        ),
      );
    } on Exception {
      throw const AppException(ServicioService.mensajeErrorElegir);
    }
  }

  @override
  Future<void> completar(String solicitudId) async {
    try {
      await _client.rpc(
        'completar_servicio',
        params: {'p_solicitud': solicitudId},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        ServicioService.traducir(
          e.message,
          ServicioService.mensajesCompletar,
          ServicioService.mensajeErrorCompletar,
        ),
      );
    } on Exception {
      throw const AppException(ServicioService.mensajeErrorCompletar);
    }
  }

  @override
  Future<List<ServicioAgendado>> misServicios() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      // RLS: la trabajadora solo lee los servicios donde está asignada.
      final filas = await _client
          .from('solicitudes')
          .select()
          .eq('trabajadora_id', usuario.id)
          .inFilter('estado', ['asignada', 'completada', 'cancelada'])
          .order('inicio', ascending: true);

      final servicios = [
        for (final fila in filas) Map<String, dynamic>.from(fila),
      ];
      final zonas = await _zonas({
        for (final fila in servicios) fila['zona_id'] as int,
      });
      final clientes = await _perfiles({
        for (final fila in servicios)
          if (fila['cliente_id'] != null) fila['cliente_id'] as String,
      });
      final calificadas = await _calificadas(
        usuario.id,
        [for (final fila in servicios) fila['id'] as String],
      );

      return [
        for (final fila in servicios)
          ServicioAgendadoModel.desdeJson(
            {...fila, 'zona': zonas[fila['zona_id']] ?? ''},
            soyCliente: false,
            contraparteNombre:
                clientes[fila['cliente_id']]?['nombre'] as String?,
            contraparteFotoUrl: _fotoUrl(
              clientes[fila['cliente_id']]?['foto_path'] as String?,
            ),
            yaCalifique: calificadas.contains(fila['id']),
          ),
      ];
    } on Exception {
      throw const AppException('No pudimos cargar tus servicios.');
    }
  }

  @override
  Future<ServicioAgendado?> servicioAgendado(String id) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    try {
      // RLS: solo el cliente dueño o la trabajadora asignada leen esta fila.
      final fila = await _client
          .from('solicitudes')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (fila == null) return null;

      final soyCliente = fila['cliente_id'] == usuario.id;
      final contraparteId =
          soyCliente ? fila['trabajadora_id'] as String? : fila['cliente_id'] as String?;

      final zonas = await _zonas({fila['zona_id'] as int});
      final contrapartes = contraparteId == null
          ? const <String, Map<String, dynamic>>{}
          : await _perfiles({contraparteId});
      final reputacion = contraparteId == null
          ? null
          : await _reputacion(contraparteId);
      final calificadas = await _calificadas(usuario.id, [id]);

      return ServicioAgendadoModel.desdeJson(
        {...fila, 'zona': zonas[fila['zona_id']] ?? ''},
        soyCliente: soyCliente,
        contraparteNombre:
            contrapartes[contraparteId]?['nombre'] as String?,
        contraparteFotoUrl: _fotoUrl(
          contrapartes[contraparteId]?['foto_path'] as String?,
        ),
        contrapartePromedio: (reputacion?['promedio'] as num?)?.toDouble(),
        yaCalifique: calificadas.contains(id),
      );
    } on Exception {
      throw const AppException('No pudimos cargar el servicio.');
    }
  }

  /// Nombre de cada zona por id.
  Future<Map<int, String>> _zonas(Set<int> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final filas = await _client
          .from('zonas')
          .select('id, nombre')
          .inFilter('id', ids.toList());
      return {
        for (final fila in filas) fila['id'] as int: fila['nombre'] as String,
      };
    } on Exception {
      return const {};
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

  /// Promedio de estrellas de la otra parte, si tiene reseñas publicadas.
  Future<Map<String, dynamic>?> _reputacion(String usuarioId) async {
    try {
      return await _client
          .from('reputacion')
          .select('promedio')
          .eq('usuario_id', usuarioId)
          .maybeSingle();
    } on Exception {
      return null;
    }
  }

  /// Solicitudes de esta lista que ya califiqué (HU-16 c4).
  Future<Set<String>> _calificadas(String autorId, List<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final filas = await _client
          .from('calificaciones')
          .select('solicitud_id')
          .eq('autor_id', autorId)
          .inFilter('solicitud_id', ids);
      return {for (final fila in filas) fila['solicitud_id'] as String};
    } on Exception {
      return const {};
    }
  }

  String? _fotoUrl(String? fotoPath) => fotoPath == null || fotoPath.isEmpty
      ? null
      : _client.storage.from('avatars').getPublicUrl(fotoPath);
}
