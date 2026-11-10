import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/conversacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/mensaje.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/chat_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/chat/mensajes_screen.dart';

class _ChatFalso implements ChatRepository {
  _ChatFalso(this.lista);

  final List<Conversacion> lista;

  @override
  Future<List<Conversacion>> conversaciones() async => lista;

  @override
  Stream<List<Mensaje>> mensajes(String solicitudId) => const Stream.empty();

  @override
  Future<void> enviar(String solicitudId, String contenido) async {}

  @override
  Future<void> marcarLeidos(String solicitudId) async {}
}

class _SesionFalsa extends SesionNotifier {
  _SesionFalsa(this.rol);

  final RolUsuario rol;

  @override
  Future<Sesion?> build() async => Sesion(
        id: rol == RolUsuario.cliente ? 'c1' : 't1',
        rol: rol,
        nombre: rol == RolUsuario.cliente ? 'María' : 'Carmen',
        perfilCompleto: true,
      );
}

Widget _app(List<Conversacion> conversaciones, RolUsuario rol) =>
    ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_ChatFalso(conversaciones)),
        sesionProvider.overrideWith(() => _SesionFalsa(rol)),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const MensajesScreen(),
      ),
    );

Conversacion _conversacion({
  required String id,
  required String nombre,
  String? ultimo,
  int noLeidos = 0,
  bool mio = false,
}) =>
    Conversacion(
      solicitudId: id,
      contraparteId: 'u-$id',
      contraparteNombre: nombre,
      tipo: TipoLimpieza.profunda,
      inicio: DateTime(2026, 11, 11, 8, 30),
      estado: EstadoSolicitud.asignada,
      ultimoMensaje: ultimo,
      ultimoEn: ultimo == null ? null : DateTime(2026, 11, 10, 9, 30),
      ultimoEsMio: mio,
      noLeidos: noLeidos,
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-38 c3: muestra contraparte, último mensaje y no leídos',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app([
      _conversacion(
        id: 's1',
        nombre: 'Carmen Pérez',
        ultimo: 'Llego a las 8:30.',
        noLeidos: 2,
      ),
      _conversacion(
        id: 's2',
        nombre: 'María Alejandra',
        ultimo: 'Gracias, nos vemos.',
        mio: true,
      ),
    ], RolUsuario.cliente));
    await tester.pumpAndSettle();

    expect(find.text('Carmen Pérez'), findsOneWidget);
    expect(find.text('Llego a las 8:30.'), findsOneWidget);
    expect(find.byKey(const Key('no-leidos-s1')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('no-leidos-s1')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Tú: Gracias, nos vemos.'), findsOneWidget);
    expect(find.byKey(const Key('no-leidos-s2')), findsNothing);
    // El aviso de la pestaña "Mensajes" suma los no leídos.
    expect(find.byKey(const Key('aviso-mensajes')), findsOneWidget);
  });

  testWidgets('HU-38: sin conversaciones muestra el estado vacío',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(_app(const [], RolUsuario.trabajadora));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes mensajes'), findsOneWidget);
    // La trabajadora también tiene la pestaña nueva.
    expect(find.text('Mensajes'), findsWidgets);
    expect(find.text('Mi reputación'), findsOneWidget);
  });
}
