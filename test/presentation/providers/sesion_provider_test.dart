import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/presentation/providers/cuenta_provider.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';

class _AuthFalsa implements AuthRepository {
  _AuthFalsa(this.sesion);

  final Sesion? sesion;
  int cerradas = 0;

  @override
  Usuario? get usuarioActual => const Usuario(id: 'u1', email: 'a@b.com');

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<Sesion?> obtenerSesion() async => sesion;

  @override
  Future<void> cerrarSesion() async => cerradas++;

  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> registrarse({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    required RolUsuario rol,
  }) async {}

  @override
  Future<void> enviarRecuperacion(String email) async {}

  @override
  Future<void> cambiarPassword(String nueva) async {}
}

Sesion _sesion({required bool activo}) => Sesion(
      id: 'u1',
      rol: RolUsuario.cliente,
      nombre: 'Qa Cuenta',
      perfilCompleto: true,
      activo: activo,
    );

void main() {
  test('HU-42: una cuenta desactivada no carga sesión y se cierra sola',
      () async {
    final auth = _AuthFalsa(_sesion(activo: false));
    final contenedor = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(contenedor.dispose);

    final resultado = await contenedor.read(sesionProvider.future);

    expect(resultado, isNull);
    expect(auth.cerradas, 1);
    expect(
      contenedor.read(avisoCuentaDesactivadaProvider),
      contains('desactivada'),
    );
  });

  test('HU-42: una cuenta activa entra normal', () async {
    final auth = _AuthFalsa(_sesion(activo: true));
    final contenedor = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(contenedor.dispose);

    final resultado = await contenedor.read(sesionProvider.future);

    expect(resultado?.activo, isTrue);
    expect(auth.cerradas, 0);
    expect(contenedor.read(avisoCuentaDesactivadaProvider), isNull);
  });
}
