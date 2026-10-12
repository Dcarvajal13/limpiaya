import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/router/redireccion.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';

void main() {
  String? ir(String ubicacion, {bool haySesion = true, RolUsuario? rol}) =>
      redirigir(ubicacion: ubicacion, haySesion: haySesion, rol: rol);

  group('sin sesión', () {
    test('puede ver la landing, el login y el registro', () {
      expect(ir(Rutas.landing, haySesion: false), isNull);
      expect(ir(Rutas.login, haySesion: false), isNull);
      expect(ir(Rutas.registro, haySesion: false), isNull);
    });

    test('cualquier otra pantalla lo manda al login', () {
      expect(ir(Rutas.inicioCliente, haySesion: false), Rutas.login);
      expect(ir(Rutas.inicio, haySesion: false), Rutas.login);
    });
  });

  group('con sesión (HU-02A / HU-02B)', () {
    test('el cliente va a Mis solicitudes', () {
      expect(ir(Rutas.login, rol: RolUsuario.cliente), Rutas.inicioCliente);
      expect(ir(Rutas.inicio, rol: RolUsuario.cliente), Rutas.inicioCliente);
    });

    test('la trabajadora va a Solicitudes disponibles', () {
      expect(ir(Rutas.login, rol: RolUsuario.trabajadora), Rutas.inicioTrabajadora);
      expect(ir(Rutas.landing, rol: RolUsuario.trabajadora), Rutas.inicioTrabajadora);
    });

    test('mientras carga el rol, espera en /inicio', () {
      expect(ir(Rutas.login), Rutas.inicio);
      expect(ir(Rutas.inicio), isNull);
    });

    test('nadie entra a las pantallas de otro rol', () {
      expect(ir(Rutas.inicioCliente, rol: RolUsuario.trabajadora), Rutas.inicioTrabajadora);
      expect(ir('${Rutas.inicioTrabajadora}/postular', rol: RolUsuario.cliente), Rutas.inicioCliente);
      expect(ir(Rutas.inicioAdmin, rol: RolUsuario.cliente), Rutas.inicioCliente);
    });

    test('cada rol se queda en su propio inicio', () {
      expect(ir(Rutas.inicioCliente, rol: RolUsuario.cliente), isNull);
      expect(ir(Rutas.inicioTrabajadora, rol: RolUsuario.trabajadora), isNull);
    });
  });

  test('el sistema de diseño se ve siempre', () {
    expect(ir(Rutas.sistemaDiseno, haySesion: false), isNull);
    expect(ir(Rutas.sistemaDiseno, rol: RolUsuario.cliente), isNull);
  });
}
