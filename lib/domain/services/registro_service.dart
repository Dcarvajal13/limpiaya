import '../../core/errors/app_exception.dart';
import '../../core/utils/mascara_telefono.dart';
import '../../core/utils/validadores.dart';
import '../entities/rol_usuario.dart';
import '../repositories/auth_repository.dart';

/// Reglas de negocio de HU-01 · Registrarme eligiendo mi rol.
///
/// Valida antes de llamar al repositorio, para que las reglas no dependan
/// de la pantalla ni de Supabase.
class RegistroService {
  RegistroService(this._repositorio);

  final AuthRepository _repositorio;

  Future<void> registrar({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario? rol,
    required bool aceptoTerminos,
  }) async {
    if (rol == null) {
      throw AppException('Elige si necesitas limpieza o quieres trabajar');
    }
    if (rol == RolUsuario.admin) {
      throw AppException('Ese rol no se puede elegir al registrarse');
    }
    if (!aceptoTerminos) {
      throw AppException('Debes aceptar los Términos y condiciones'); // HU-01 c5
    }

    // Taller UX, H5: "04141234567" también vale; se guarda con el guion.
    final telefonoConGuion = MascaraTelefono.formatear(telefono);

    final error = Validadores.requerido(nombre) ??
        Validadores.email(email) ??
        Validadores.telefono(telefonoConGuion) ??
        Validadores.password(password);
    if (error != null) throw AppException(error); // HU-01 c3 y c4

    await _repositorio.registrarse(
      nombre: nombre.trim(),
      email: email.trim().toLowerCase(),
      telefono: telefonoConGuion,
      password: password,
      rol: rol,
    );
  }
}