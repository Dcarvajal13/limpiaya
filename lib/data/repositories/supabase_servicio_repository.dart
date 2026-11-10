import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/servicio_repository.dart';
import '../../domain/services/servicio_service.dart';

/// Implementación de ServicioRepository usando Supabase.
///
/// Cada acción llama a una función de Postgres (migraciones de HU-15 en
/// adelante) que revisa los permisos y cambia los estados en un solo paso.
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
}
