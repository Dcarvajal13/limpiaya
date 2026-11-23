import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/cuenta_repository.dart';

/// Implementación de CuentaRepository con Supabase (HU-39 y HU-42).
class SupabaseCuentaRepository implements CuentaRepository {
  SupabaseCuentaRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw const AppException('Inicia sesión para cambiar tu contraseña');
    }

    // Supabase no pide la contraseña actual para cambiarla: la comprobamos
    // volviendo a iniciar sesión con ella (criterio 2).
    try {
      await _client.auth.signInWithPassword(email: email, password: actual);
    } on AuthException {
      throw const AppException('La contraseña actual no es correcta');
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: nueva));
    } on AuthException catch (e) {
      if (e.code == 'same_password') {
        throw const AppException(
          'La contraseña nueva debe ser distinta a la actual',
        );
      }
      if (e.code == 'weak_password') {
        throw const AppException('Elige una contraseña más segura');
      }
      throw const AppException(
        'No pudimos guardar la contraseña. Intenta de nuevo.',
      );
    } on Exception {
      throw const AppException(
        'No pudimos guardar la contraseña. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  @override
  Future<void> desactivar() async {
    try {
      await _client.rpc('desactivar_cuenta');
    } on PostgrestException catch (e) {
      // Criterio 2: la base no deja desactivar con servicios asignados.
      if (e.message.contains('servicios asignados')) {
        throw const AppException(
          'Primero completa o cancela tus servicios asignados.',
        );
      }
      throw const AppException(
        'No pudimos desactivar tu cuenta. Intenta de nuevo.',
      );
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }
}
