import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/rol_usuario.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementación de AuthRepository usando Supabase Auth.
///
/// Es la ÚNICA parte de la app que habla con Supabase para autenticación.
/// Cada historia completa aquí su método (ver los TODO).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Usuario? get usuarioActual => _aUsuario(_client.auth.currentUser);

  @override
  Stream<Usuario?> cambiosDeSesion() {
    return _client.auth.onAuthStateChange
        .map((evento) => _aUsuario(evento.session?.user));
  }

  @override
  Future<void> registrarse({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario rol,
  }) {
    // TODO(HU-01): llamar a _client.auth.signUp(...) enviando nombre,
    // teléfono y rol en `data`, y convertir los errores en AppException
    // (por ejemplo "Este correo ya tiene una cuenta").
    throw UnimplementedError('Pendiente: HU-01');
  }

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) {
    // TODO(HU-02A/HU-02B): llamar a _client.auth.signInWithPassword(...)
    // y convertir los errores en AppException
    // ("Correo o contraseña incorrectos").
    throw UnimplementedError('Pendiente: HU-02A / HU-02B');
  }

  @override
  Future<void> cerrarSesion() {
    // TODO(HU-03): llamar a _client.auth.signOut().
    throw UnimplementedError('Pendiente: HU-03');
  }

  /// Convierte el usuario de Supabase en la entidad del dominio.
  Usuario? _aUsuario(User? user) {
    if (user == null) return null;
    return Usuario(id: user.id, email: user.email ?? '');
  }
}
