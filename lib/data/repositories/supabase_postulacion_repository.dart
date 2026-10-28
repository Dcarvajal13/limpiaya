import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/estado_postulacion.dart';
import '../../domain/entities/estado_solicitud.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/repositories/postulacion_repository.dart';
import '../../domain/services/postulacion_service.dart';
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

  @override
  Future<void> postular({
    required String solicitudId,
    String? mensaje,
  }) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException(PostulacionService.mensajeSesion);
    }

    try {
      // c2 · ¿Ya tengo una postulación viva para esta solicitud? Las retiradas
      // no cuentan: puede volver a postularse (HU-26).
      final previas = await _client
          .from('postulaciones')
          .select('id, estado')
          .eq('solicitud_id', solicitudId)
          .eq('trabajadora_id', usuario.id);
      final vivas = previas.where(
        (p) => p['estado'] != EstadoPostulacion.retirada.valorDb,
      );
      if (vivas.isNotEmpty) {
        throw const AppException(PostulacionService.mensajeYaPostulada);
      }

      // c3 · La solicitud a la que me postulo: de la vista pública salen el
      // inicio y el fin, que es todo lo que necesito para comparar horarios.
      final solicitud = await _client
          .from('solicitudes_publicas')
          .select('estado, inicio, fin, horas_estimadas')
          .eq('id', solicitudId)
          .maybeSingle();
      // HU-45 c3 · Pudo asignarse o cancelarse mientras miraba el detalle.
      if (solicitud == null ||
          solicitud['estado'] != EstadoSolicitud.publicada.valorDb) {
        throw const AppException(PostulacionService.mensajeNoDisponible);
      }

      // RLS: solo puedo leer las solicitudes que tengo asignadas (o publiqué).
      final misServicios = await _client
          .from('solicitudes')
          .select('inicio, fin, horas_estimadas')
          .eq('trabajadora_id', usuario.id)
          .inFilter('estado', [
        EstadoSolicitud.asignada.valorDb,
        EstadoSolicitud.completada.valorDb,
      ]);

      final inicio = _fecha(solicitud['inicio'])!;
      final fin = _fecha(solicitud['fin']) ??
          inicio.add(
            Duration(
              minutes:
                  ((solicitud['horas_estimadas'] as num?) ?? 0).round() * 60,
            ),
          );
      final ocupados = <(DateTime, DateTime)>[
        for (final fila in misServicios)
          if (_fecha(fila['inicio']) case final otroInicio?)
            (
              otroInicio,
              _fecha(fila['fin']) ??
                  otroInicio.add(
                    Duration(
                      minutes:
                          ((fila['horas_estimadas'] as num?) ?? 0).round() * 60,
                    ),
                  ),
            ),
      ];
      if (PostulacionService.seCruza(
        inicio: inicio,
        fin: fin,
        servicios: ocupados,
      )) {
        throw const AppException(PostulacionService.mensajeSolape);
      }

      final texto = mensaje?.trim();
      await _client.from('postulaciones').insert({
        'solicitud_id': solicitudId,
        'trabajadora_id': usuario.id,
        'mensaje': (texto == null || texto.isEmpty) ? null : texto,
      });
    } on AppException {
      rethrow;
    } on PostgrestException catch (e) {
      // La política de la base rechaza la postulación si la solicitud dejó de
      // estar Publicada entre la comprobación y el insert.
      if (e.code == '42501') {
        throw const AppException(PostulacionService.mensajeNoDisponible);
      }
      throw const AppException(PostulacionService.mensajeError);
    } on Exception {
      throw const AppException(PostulacionService.mensajeError);
    }
  }

  @override
  Future<void> retirar(String postulacionId) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException(PostulacionService.mensajeSesion);
    }

    try {
      // HU-26 · La política RLS solo deja pasar mis postulaciones pendientes y
      // exige que queden en 'retirada'. Si no devuelve filas, es porque ya no
      // está pendiente (la aceptaron) o no es mía.
      final filas = await _client
          .from('postulaciones')
          .update({'estado': EstadoPostulacion.retirada.valorDb})
          .eq('id', postulacionId)
          .eq('trabajadora_id', usuario.id)
          .eq('estado', EstadoPostulacion.pendiente.valorDb)
          .select('id');
      if (filas.isEmpty) {
        throw const AppException(PostulacionService.mensajeSoloPendiente);
      }
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException(PostulacionService.mensajeErrorRetirar);
    }
  }

  /// `timestamptz` de Postgres → fecha local de quien la mira.
  DateTime? _fecha(Object? valor) {
    if (valor is! String || valor.isEmpty) return null;
    return DateTime.tryParse(valor)?.toLocal();
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
