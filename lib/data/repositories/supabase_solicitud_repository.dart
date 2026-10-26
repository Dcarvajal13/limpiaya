import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/solicitud_disponible.dart';
import '../../domain/entities/zona.dart';
import '../../domain/repositories/solicitud_repository.dart';
import '../models/solicitud_model.dart';
import '../../domain/entities/direccion_cliente.dart';
import '../../domain/entities/nueva_solicitud.dart';

/// Implementación de SolicitudRepository usando Supabase.
///
/// Es la ÚNICA parte de la app que habla con Supabase para solicitudes.
/// Cada historia completa aquí su método.
class SupabaseSolicitudRepository implements SolicitudRepository {
  SupabaseSolicitudRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Zona>> misZonas() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return const [];
    try {
      // RLS: la trabajadora solo lee sus propias filas de trabajadora_zonas.
      final filas = await _client
          .from('trabajadora_zonas')
          .select('zonas(id, nombre)')
          .eq('trabajadora_id', usuario.id);

      final zonas = [
        for (final fila in filas)
          if (fila['zonas'] != null)
            SolicitudModel.zonaDesdeJson(
              Map<String, dynamic>.from(fila['zonas'] as Map),
            ),
      ]..sort((a, b) => a.nombre.compareTo(b.nombre));
      return zonas;
    } on Exception {
      throw const AppException('No pudimos cargar tus zonas.');
    }
  }

  @override
  Future<List<SolicitudDisponible>> disponibles() async {
    final zonas = await misZonas();
    // Sin zonas en el perfil no hay nada que mostrar (HU-04 las configura).
    if (zonas.isEmpty) return const [];

    try {
      // La vista solicitudes_publicas también devuelve solicitudes que la
      // trabajadora ya tiene asignadas o a las que se postuló, por eso se
      // vuelve a filtrar aquí por estado, fecha futura y zonas (HU-11 c1).
      // Nunca incluye la dirección exacta.
      final filas = await _client
          .from('solicitudes_publicas')
          .select()
          .eq('estado', 'publicada')
          .gt('inicio', DateTime.now().toUtc().toIso8601String())
          .inFilter('zona_id', [for (final zona in zonas) zona.id])
          .order('inicio', ascending: true);

      return [
        for (final fila in filas)
          SolicitudModel.disponibleDesdeJson(Map<String, dynamic>.from(fila)),
      ];
    } on Exception {
      throw const AppException('No pudimos cargar las solicitudes.');
    }
  }

    @override
  Future<String> publicar(NuevaSolicitud solicitud) async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw const AppException('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    try {
      // RLS: el cliente solo puede crear solicitudes a su nombre.
      final fila = await _client
          .from('solicitudes')
          .insert(SolicitudModel.nuevaAJson(solicitud, usuario.id))
          .select('id')
          .single();
      return fila['id'] as String;
    } on PostgrestException catch (e) {
      // El trigger de la base rechaza las fechas pasadas (HU-07 c2).
      if (e.message.contains('La fecha debe ser futura')) {
        throw const AppException('La fecha debe ser futura');
      }
      throw const AppException(
        'No pudimos publicar la solicitud. Revisa los datos e intenta de nuevo.',
      );
    } on Exception {
      throw const AppException(
        'No pudimos publicar la solicitud. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  @override
  Future<DireccionCliente?> miDireccion() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return null;
    try {
      final fila = await _client
          .from('clientes')
          .select('zona_id, direccion, punto_referencia')
          .eq('id', usuario.id)
          .maybeSingle();
      return fila == null ? null : SolicitudModel.direccionDesdeJson(fila);
    } on Exception {
      // Si falla, el formulario simplemente sale vacío.
      return null;
    }
  }
}
