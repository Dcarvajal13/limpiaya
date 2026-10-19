import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/perfil_cliente.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/usuario.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/auth_repository.dart';
import 'package:limpiaya/domain/repositories/cliente_repository.dart';
import 'package:limpiaya/presentation/screens/cliente/perfil_cliente_screen.dart';

/// Repositorio falso: guarda en memoria lo que le mandan.
class _ClienteFalso implements ClienteRepository {
  PerfilCliente perfil = const PerfilCliente();
  int? ultimoZonaId;
  String? ultimaDireccion;

  @override
  Future<List<Zona>> zonasDisponibles() async => const [
        Zona(id: 1, nombre: 'Sabana Grande'),
        Zona(id: 2, nombre: 'Altamira'),
      ];

  @override
  Future<PerfilCliente> miPerfil() async => perfil;

  @override
  Future<void> guardarPerfil({
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    ultimoZonaId = zonaId;
    ultimaDireccion = direccion;
    perfil = PerfilCliente(
      zona: Zona(id: zonaId, nombre: 'Sabana Grande'),
      direccion: direccion,
      puntoReferencia: puntoReferencia,
    );
  }
}

/// Auth falso: hay sesión de cliente sin el perfil completo.
class _AuthFalso implements AuthRepository {
  @override
  Usuario? get usuarioActual => const Usuario(id: 'u1', email: 'ana@correo.com');

  @override
  Stream<Usuario?> cambiosDeSesion() => const Stream.empty();

  @override
  Future<void> cerrarSesion() async {}

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
  Future<Sesion?> obtenerSesion() async => const Sesion(
        id: 'u1',
        rol: RolUsuario.cliente,
        nombre: 'Ana',
        perfilCompleto: false,
      );
}

Widget _app(_ClienteFalso repo) {
  return ProviderScope(
    overrides: [
      clienteRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(_AuthFalso()),
    ],
    child: MaterialApp(
      theme: AppTheme.claro,
      home: const PerfilClienteScreen(),
    ),
  );
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-05: sin zona no guarda y avisa "Elige tu zona"', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu zona'), findsOneWidget);
    expect(repo.ultimoZonaId, isNull);
  });

  testWidgets('HU-05: dirección de menos de 5 caracteres no guarda', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sabana Grande').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe al menos 5 caracteres'), findsOneWidget);
    expect(repo.ultimoZonaId, isNull);
  });

  testWidgets('HU-05: guarda la zona y la dirección', (tester) async {
    final repo = _ClienteFalso();
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    // Elegir la zona en el menú desplegable.
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sabana Grande').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).first, 'Av. Francisco de Miranda');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repo.ultimoZonaId, 1);
    expect(repo.ultimaDireccion, 'Av. Francisco de Miranda');
    expect(find.text('Perfil guardado'), findsOneWidget);
  });
}
