import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/domain/services/registro_service.dart';

/// Repositorio falso: no habla con Supabase, solo cuenta las llamadas.
class _RepositorioFalso implements AuthRepository {
  int registros = 0;
  String? ultimoTelefono;

  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}

  @override
  Usuario? get usuarioActual => null;

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> registrarse({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario rol,
  }) async {
    registros++;
    ultimoTelefono = telefono;
  }

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {}

  @override
  Future<Sesion?> obtenerSesion() async => null;

  @override
  Future<void> cerrarSesion() async {}
}

void main() {
  late _RepositorioFalso repo;
  late RegistroService servicio;

  setUp(() {
    repo = _RepositorioFalso();
    servicio = RegistroService(repo);
  });

  Future<void> registrar({
    String telefono = '0414-1234567',
    String password = 'secreta123',
    RolUsuario? rol = RolUsuario.cliente,
    bool terminos = true,
  }) {
    return servicio.registrar(
      nombre: 'María Alejandra',
      email: 'maria@gmail.com',
      telefono: telefono,
      password: password,
      rol: rol,
      aceptoTerminos: terminos,
    );
  }

  test('HU-01 c1: con datos válidos crea la cuenta', () async {
    await registrar();
    expect(repo.registros, 1);
  });

  test('HU-01 c3: rechaza un teléfono incompleto o que no empieza por 04', () {
    expect(registrar(telefono: '0414-123'), throwsA(isA<AppException>()));
    expect(registrar(telefono: '02121234567'), throwsA(isA<AppException>()));
  });

  test('taller UX (H5): el teléfono sin guion se acepta y se guarda con él',
      () async {
    await registrar(telefono: '04141234567');
    expect(repo.ultimoTelefono, '0414-1234567');
  });

  test('HU-01 c4: rechaza contraseñas de menos de 8 caracteres', () {
    expect(registrar(password: '1234'), throwsA(isA<AppException>()));
  });

  test('HU-01 c5: exige aceptar los Términos y condiciones', () {
    expect(registrar(terminos: false), throwsA(isA<AppException>()));
  });

  test('no permite registrarse sin rol ni como administrador', () {
    expect(registrar(rol: null), throwsA(isA<AppException>()));
    expect(registrar(rol: RolUsuario.admin), throwsA(isA<AppException>()));
  });
}