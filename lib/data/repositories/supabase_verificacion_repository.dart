import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/verificacion_pendiente.dart';
import '../../domain/repositories/verificacion_repository.dart';
import '../models/verificacion_model.dart';

/// Implementación de VerificacionRepository usando Supabase.
///
/// Permisos (ya existen en las migraciones):
/// - RLS: solo el admin lee todas las verificaciones y puede aprobarlas o
///   rechazarlas ("verificaciones: el admin aprueba o rechaza").
/// - Storage: el bucket "verificaciones" es privado; el admin puede ver las
///   fotos, por eso se piden links temporales.
class SupabaseVerificacionRepository implements VerificacionRepository {
  SupabaseVerificacionRepository(this._client);

  final SupabaseClient _client;

  static const _bucketVerificaciones = 'verificaciones';
  static const _bucketAvatars = 'avatars';

  /// Los links a las fotos privadas duran una hora.
  static const _segundosLink = 60 * 60;

  @override
  Future<List<VerificacionPendiente>> pendientes() async {
    final List<Map<String, dynamic>> filas;
    try {
      // HU-33 c1: en revisión, de la más antigua a la más reciente.
      final respuesta = await _client
          .from('verificaciones')
          .select(
            'id, trabajadora_id, cedula_path, selfie_path, created_at, '
            'trabajadoras(perfiles(nombre, telefono, foto_path, created_at))',
          )
          .eq('estado', 'en_revision')
          .order('created_at', ascending: true);
      filas = [for (final fila in respuesta) Map<String, dynamic>.from(fila)];
    } on Exception {
      throw const AppException('No pudimos cargar las verificaciones.');
    }

    return Future.wait([for (final fila in filas) _conFotos(fila)]);
  }

  Future<VerificacionPendiente> _conFotos(Map<String, dynamic> fila) async {
    final links = await Future.wait([
      _linkTemporal(fila['cedula_path'] as String?),
      _linkTemporal(fila['selfie_path'] as String?),
    ]);

    final fotoPath = VerificacionModel.fotoPath(fila);
    return VerificacionModel.pendienteDesdeJson(
      fila,
      fotoUrl: fotoPath == null
          ? null
          : _client.storage.from(_bucketAvatars).getPublicUrl(fotoPath),
      cedulaUrl: links[0],
      selfieUrl: links[1],
    );
  }

  /// Link temporal a una foto privada, o null si no se pudo generar.
  Future<String?> _linkTemporal(String? ruta) async {
    if (ruta == null || ruta.isEmpty) return null;
    try {
      return await _client.storage
          .from(_bucketVerificaciones)
          .createSignedUrl(ruta, _segundosLink);
    } on Exception {
      // La pantalla muestra "No se pudo cargar la foto".
      return null;
    }
  }

  @override
  Future<void> aprobar(String id) =>
      _revisar(id, {'estado': 'aprobada', 'motivo_rechazo': null});

  @override
  Future<void> rechazar(String id, String motivo) =>
      _revisar(id, {'estado': 'rechazada', 'motivo_rechazo': motivo});

  Future<void> _revisar(String id, Map<String, dynamic> cambios) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }

    final List<dynamic> filas;
    try {
      // Solo se cambia si sigue en revisión, para no pisar una revisión hecha
      // en otra pestaña. El trigger sincronizar_verificacion copia el estado
      // a la trabajadora (HU-33 c2).
      filas = await _client
          .from('verificaciones')
          .update({
            ...cambios,
            'revisada_por': usuario.id,
            'revisada_en': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .eq('estado', 'en_revision')
          .select('id');
    } on PostgrestException catch (e) {
      // 23514: la restricción rechazo_requiere_motivo (HU-33 c3).
      if (e.code == '23514') throw const AppException('Indica el motivo');
      throw const AppException('No pudimos guardar la revisión. Intenta de nuevo.');
    } on Exception {
      throw const AppException(
        'No pudimos guardar la revisión. Revisa tu conexión e intenta de nuevo.',
      );
    }

    if (filas.isEmpty) {
      throw const AppException(
        'Esta verificación ya fue revisada. Actualiza la lista.',
      );
    }
  }
}
