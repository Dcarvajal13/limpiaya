import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/router/redireccion.dart';
import 'package:limpiaya/core/router/rutas.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';

void main() {
  String? ir(String ubicacion,
          {bool haySesion = true,
          RolUsuario? rol,
          bool perfilCompleto = true,
          bool recuperando = false}) =>
      redirigir(
        ubicacion: ubicacion,
        haySesion: haySesion,
        rol: rol,
        perfilCompleto: perfilCompleto,
        recuperandoContrasena: recuperando,
      );

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

  group('HU-05 · perfil del cliente', () {
    test('recién registrado: lo mandan a completar su perfil', () {
      expect(
        ir(Rutas.inicioCliente, rol: RolUsuario.cliente, perfilCompleto: false),
        Rutas.perfilCliente,
      );
    });

    test('recién registrado: desde /inicio va directo al perfil', () {
      expect(
        ir(Rutas.inicio, rol: RolUsuario.cliente, perfilCompleto: false),
        Rutas.perfilCliente,
      );
    });

    test('con el perfil completo entra a Mis solicitudes', () {
      expect(
        ir(Rutas.inicioCliente, rol: RolUsuario.cliente, perfilCompleto: true),
        isNull,
      );
    });

    test('puede abrir su perfil aunque esté incompleto', () {
      expect(
        ir(Rutas.perfilCliente, rol: RolUsuario.cliente, perfilCompleto: false),
        isNull,
      );
    });

    test('la trabajadora no entra al perfil del cliente', () {
      expect(
        ir(Rutas.perfilCliente, rol: RolUsuario.trabajadora),
        Rutas.inicioTrabajadora,
      );
    });
  });

  group('HU-04 · perfil de la trabajadora', () {
    test('recién registrada: la mandan a completar su perfil', () {
      expect(
        ir(Rutas.inicioTrabajadora,
            rol: RolUsuario.trabajadora, perfilCompleto: false),
        Rutas.perfilTrabajadora,
      );
    });

    test('recién registrada: desde /inicio va directo al perfil', () {
      expect(
        ir(Rutas.inicio, rol: RolUsuario.trabajadora, perfilCompleto: false),
        Rutas.perfilTrabajadora,
      );
    });

    test('con el perfil completo entra a las solicitudes', () {
      expect(
        ir(Rutas.inicioTrabajadora,
            rol: RolUsuario.trabajadora, perfilCompleto: true),
        isNull,
      );
    });

    test('puede abrir su perfil aunque esté incompleto', () {
      expect(
        ir(Rutas.perfilTrabajadora,
            rol: RolUsuario.trabajadora, perfilCompleto: false),
        isNull,
      );
    });

    test('el cliente no entra al perfil de la trabajadora', () {
      expect(
        ir(Rutas.perfilTrabajadora, rol: RolUsuario.cliente),
        Rutas.inicioCliente,
      );
    });
  });

  group('HD-06 · administrador', () {
    test('al iniciar sesión entra al panel de administración', () {
      expect(ir(Rutas.login, rol: RolUsuario.admin), Rutas.inicioAdmin);
      expect(ir(Rutas.inicio, rol: RolUsuario.admin), Rutas.inicioAdmin);
      expect(ir(Rutas.inicioAdmin, rol: RolUsuario.admin), isNull);
    });

    test('cliente y trabajadora no abren el panel por su URL', () {
      expect(ir(Rutas.inicioAdmin, rol: RolUsuario.cliente), Rutas.inicioCliente);
      expect(ir(Rutas.inicioAdmin, rol: RolUsuario.trabajadora),
          Rutas.inicioTrabajadora);
      expect(ir('${Rutas.inicioAdmin}/verificaciones', rol: RolUsuario.trabajadora),
          Rutas.inicioTrabajadora);
    });

    test('el admin no entra a pantallas de cliente ni de trabajadora', () {
      expect(ir(Rutas.inicioCliente, rol: RolUsuario.admin), Rutas.inicioAdmin);
      expect(ir(Rutas.inicioTrabajadora, rol: RolUsuario.admin), Rutas.inicioAdmin);
    });
  });

  test('el sistema de diseño se ve siempre', () {
    expect(ir(Rutas.sistemaDiseno, haySesion: false), isNull);
    expect(ir(Rutas.sistemaDiseno, rol: RolUsuario.cliente), isNull);
  });

  group('HU-19 · recuperar contraseña', () {
    test('sin sesión se puede abrir "¿Olvidaste tu contraseña?"', () {
      expect(ir(Rutas.recuperarContrasena, haySesion: false), isNull);
    });

    test('sin sesión no se puede abrir "Nueva contraseña"', () {
      expect(ir(Rutas.nuevaContrasena, haySesion: false), Rutas.login);
    });

    test('con el enlace del correo va directo a "Nueva contraseña"', () {
      for (final ubicacion in [Rutas.landing, Rutas.inicio, Rutas.inicioCliente]) {
        expect(
          ir(ubicacion, rol: RolUsuario.cliente, recuperando: true),
          Rutas.nuevaContrasena,
        );
      }
      expect(
        ir(Rutas.nuevaContrasena, rol: RolUsuario.trabajadora, recuperando: true),
        isNull,
      );
    });

    test('después de guardarla ya no la obliga', () {
      expect(ir(Rutas.inicio, rol: RolUsuario.cliente), Rutas.inicioCliente);
    });
  });
}
