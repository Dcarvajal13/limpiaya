import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/cuenta_usuario.dart';
import '../../domain/entities/metricas_plataforma.dart';
import '../../domain/entities/resena_reportada.dart';
import '../../domain/entities/rol_usuario.dart';
import '../../domain/repositories/admin_repository.dart';

/// Implementación Supabase de [AdminRepository] para HU-34, HU-35 y HU-36.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CuentaUsuario>> listarCuentas() async {
    try {
      final res = await _client.rpc('listar_cuentas_admin');
      if (res is! List) return const [];
      return res.map((raw) {
        final f = Map<String, dynamic>.from(raw as Map);
        final fotoPath = f['foto_path'] as String?;
        return CuentaUsuario(
          id: f['id'] as String,
          nombre: f['nombre'] as String? ?? 'Sin nombre',
          rol: RolUsuario.values.byName(f['rol'] as String),
          fotoUrl: fotoPath == null
              ? null
              : _client.storage.from('avatars').getPublicUrl(fotoPath),
          activo: f['activo'] as bool? ?? true,
          suspendido: f['suspendido'] as bool? ?? false,
          motivoSuspension: f['motivo_suspension'] as String?,
          suspendidoEn: f['suspendido_en'] == null
              ? null
              : DateTime.parse(f['suspendido_en'] as String).toLocal(),
          verificacion: f['verificacion'] as String?,
          serviciosActivos: (f['servicios_activos'] as num?)?.toInt() ?? 0,
          creadoEn: DateTime.parse(f['creado_en'] as String).toLocal(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty ? e.message : 'No pudimos cargar las cuentas.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<void> suspenderCuenta(String usuarioId, String motivo) async {
    try {
      await _client.rpc(
        'suspender_cuenta',
        params: {'p_usuario': usuarioId, 'p_motivo': motivo},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty
            ? e.message
            : 'No pudimos suspender la cuenta.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<void> reactivarCuenta(String usuarioId) async {
    try {
      await _client.rpc(
        'reactivar_cuenta',
        params: {'p_usuario': usuarioId},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty
            ? e.message
            : 'No pudimos reactivar la cuenta.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<List<ResenaReportada>> listarResenasReportadas() async {
    try {
      final res = await _client.rpc('listar_resenas_reportadas');
      if (res is! List) return const [];
      return res.map((raw) {
        final f = Map<String, dynamic>.from(raw as Map);
        return ResenaReportada(
          reporteId: f['reporte_id'] as String,
          calificacionId: f['calificacion_id'] as String,
          estrellas: (f['estrellas'] as num).toInt(),
          comentario: f['comentario'] as String?,
          autorNombre: f['autor_nombre'] as String? ?? 'Usuario',
          destinatarioNombre: f['destinatario_nombre'] as String? ?? 'Usuario',
          reportadoPorNombre:
              f['reportado_por_nombre'] as String? ?? 'Usuario',
          motivoReporte: f['motivo_reporte'] as String? ?? '',
          estado: f['estado'] as String? ?? 'pendiente',
          notaAdmin: f['nota_admin'] as String?,
          creadoEn: DateTime.parse(f['creado_en'] as String).toLocal(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty
            ? e.message
            : 'No pudimos cargar la cola de moderación.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<void> ocultarResena(String reporteId, {String? nota}) =>
      _moderar(reporteId, 'ocultar', nota: nota);

  @override
  Future<void> mantenerResena(String reporteId, {String? nota}) =>
      _moderar(reporteId, 'mantener', nota: nota);

  Future<void> _moderar(String reporteId, String accion, {String? nota}) async {
    try {
      await _client.rpc(
        'moderar_resena',
        params: {
          'p_reporte': reporteId,
          'p_accion': accion,
          if (nota != null && nota.isNotEmpty) 'p_nota': nota,
        },
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty ? e.message : 'No pudimos moderar la reseña.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<void> reportarResena(String calificacionId, String motivo) async {
    try {
      await _client.rpc(
        'reportar_resena',
        params: {'p_calificacion': calificacionId, 'p_motivo': motivo},
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty ? e.message : 'No pudimos enviar el reporte.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<MetricasPlataforma> metricas(DateTime mes) async {
    final mesStr =
        '${mes.year.toString().padLeft(4, '0')}-${mes.month.toString().padLeft(2, '0')}-01';
    try {
      final raw = await _client.rpc(
        'metricas_plataforma',
        params: {'p_mes': mesStr},
      );
      final d = Map<String, dynamic>.from(raw as Map);
      return MetricasPlataforma(
        mes: DateTime.parse(d['mes'] as String),
        totalSolicitudes: (d['total_solicitudes'] as num?)?.toInt() ?? 0,
        solicitudesConPostulacion:
            (d['solicitudes_con_postulacion'] as num?)?.toInt() ?? 0,
        pctConPostulacion:
            (d['pct_con_postulacion'] as num?)?.toDouble() ?? 0,
        solicitudesAsignadas:
            (d['solicitudes_asignadas'] as num?)?.toInt() ?? 0,
        solicitudesCompletadas:
            (d['solicitudes_completadas'] as num?)?.toInt() ?? 0,
        solicitudesCanceladas:
            (d['solicitudes_canceladas'] as num?)?.toInt() ?? 0,
        pctCompletado: (d['pct_completado'] as num?)?.toDouble() ?? 0,
        clientesNuevos: (d['clientes_nuevos'] as num?)?.toInt() ?? 0,
        trabajadorasNuevas: (d['trabajadoras_nuevas'] as num?)?.toInt() ?? 0,
        trabajadorasVerificadas:
            (d['trabajadoras_verificadas'] as num?)?.toInt() ?? 0,
        volumenUsd: (d['volumen_usd'] as num?)?.toDouble() ?? 0,
      );
    } on PostgrestException catch (e) {
      throw AppException(
        e.message.isNotEmpty ? e.message : 'No pudimos cargar las métricas.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }
}
