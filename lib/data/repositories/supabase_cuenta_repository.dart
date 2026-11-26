import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/datos_personales.dart';
import '../../domain/repositories/cuenta_repository.dart';

/// Implementación de CuentaRepository con Supabase (HU-39, HU-41 y HU-42).
class SupabaseCuentaRepository implements CuentaRepository {
  SupabaseCuentaRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DatosPersonales> datosPersonales() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException('Inicia sesión para ver tus datos');
    }

    try {
      final fila = await _client
          .from('perfiles')
          .select('nombre, telefono')
          .eq('id', uid)
          .maybeSingle();
      if (fila == null) {
        throw const AppException('No encontramos tu perfil.');
      }
      return DatosPersonales(
        nombre: (fila['nombre'] as String?) ?? '',
        telefono: (fila['telefono'] as String?) ?? '',
      );
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException(
        'No pudimos cargar tus datos. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  @override
  Future<void> actualizarDatos({
    required String nombre,
    required String telefono,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException('Inicia sesión para editar tus datos');
    }

    try {
      final fila = await _client
          .from('perfiles')
          .update({'nombre': nombre.trim(), 'telefono': telefono.trim()})
          .eq('id', uid)
          .select('id')
          .maybeSingle();
      if (fila == null) {
        throw const AppException('No encontramos tu perfil.');
      }
    } on AppException {
      rethrow;
    } on Exception {
      throw const AppException(
        'No pudimos guardar tus datos. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

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
