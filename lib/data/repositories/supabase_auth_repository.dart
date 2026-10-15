import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/rol_usuario.dart';
import '../../domain/entities/sesion.dart';
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
  }) async {
    try {
      final respuesta = await _client.auth.signUp(
        email: email,
        password: password,
        // El trigger de la base de datos lee estos datos y crea el perfil.
        data: {
          'nombre': nombre,
          'telefono': telefono,
          'rol': rol.name,
        },
      );

      // Si el correo ya existe y la confirmación por correo está activa,
      // Supabase no da error: devuelve un usuario sin identidades.
      final identidades = respuesta.user?.identities;
      if (identidades != null && identidades.isEmpty) {
        throw AppException('Este correo ya tiene una cuenta');
      }
    } on AuthException catch (e) {
      final yaExiste = e.code == 'user_already_exists' ||
          e.message.toLowerCase().contains('already registered');
      if (yaExiste) {
        throw AppException('Este correo ya tiene una cuenta'); // HU-01 c2
      }
      throw AppException('No pudimos crear tu cuenta. Intenta de nuevo.');
    }
  }

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      final datosIncorrectos = e.code == 'invalid_credentials' ||
          e.message.toLowerCase().contains('invalid login credentials');
      if (datosIncorrectos) {
        // No decimos cuál de los dos está mal, para no revelar
        // qué correos tienen cuenta.
        throw const AppException('Correo o contraseña incorrectos');
      }
      if (e.code == 'email_not_confirmed') {
        throw const AppException('Confirma tu correo antes de entrar');
      }
      throw const AppException('No pudimos iniciar sesión. Intenta de nuevo.');
    } on Exception {
      throw const AppException('Revisa tu conexión e intenta de nuevo.');
    }
  }

  @override
  Future<Sesion?> obtenerSesion() async {
    if (_client.auth.currentUser == null) return null;
    try {
      final datos = await _client.rpc('mi_sesion');
      if (datos is! Map) return null; // Tiene usuario pero no perfil.
      return _aSesion(Map<String, dynamic>.from(datos));
    } on Exception {
      throw const AppException('No pudimos cargar tu cuenta.');
    }
  }

  @override
  Future<void> cerrarSesion() async {
    try {
      await _client.auth.signOut();
    } on Exception {
      throw const AppException('No pudimos cerrar tu sesión. Intenta de nuevo.');
    }
  }

  /// Convierte la respuesta de `mi_sesion()` en la entidad del dominio.
  Sesion _aSesion(Map<String, dynamic> datos) {
    final fotoPath = datos['foto_path'] as String?;
    return Sesion(
      id: datos['id'] as String,
      rol: RolUsuario.values.byName(datos['rol'] as String),
      nombre: datos['nombre'] as String? ?? '',
      perfilCompleto: datos['perfil_completo'] as bool? ?? false,
      fotoPath: fotoPath,
      fotoUrl: fotoPath == null
          ? null
          : _client.storage.from('avatars').getPublicUrl(fotoPath),
      verificacion: datos['verificacion'] as String?,
    );
  }

  /// Convierte el usuario de Supabase en la entidad del dominio.
  Usuario? _aUsuario(User? user) {
    if (user == null) return null;
    return Usuario(id: user.id, email: user.email ?? '');
  }
}
