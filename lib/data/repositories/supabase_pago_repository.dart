import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/pago.dart';
import '../../domain/repositories/pago_repository.dart';
import '../models/pago_model.dart';

/// Implementación de PagoRepository usando Supabase.
///
/// El cobro lo hace la función `pagar_servicio` (migración
/// 20261118100000_pagos.sql): calcula los montos desde la solicitud, revisa
/// que quien paga sea el cliente dueño y guarda una sola fila por servicio.
class SupabasePagoRepository implements PagoRepository {
  SupabasePagoRepository(this._client);

  final SupabaseClient _client;

  static const mensajeError = 'No pudimos registrar el pago. Intenta de nuevo.';

  @override
  Future<Pago> pagar(String solicitudId) async {
    if (solicitudId.trim().isEmpty) {
      throw const AppException(mensajeError);
    }
    try {
      final fila = await _client.rpc(
        'pagar_servicio',
        params: {'p_solicitud': solicitudId},
      );
      return PagoModel.desdeJson(Map<String, dynamic>.from(fila as Map));
    } on PostgrestException catch (e) {
      throw AppException(switch (e.message) {
        final m when m.contains('No encontramos ese servicio') =>
          'No encontramos ese servicio',
        final m when m.contains('Solo puedes pagar un servicio asignado') =>
          'Este servicio no se puede pagar',
        _ => mensajeError,
      });
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException(mensajeError);
    }
  }
}
