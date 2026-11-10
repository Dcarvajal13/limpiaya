import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/di/providers.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/conversacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/mensaje.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/servicio_agendado.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/repositories/chat_repository.dart';
import 'package:limpiaya/domain/repositories/servicio_repository.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';
import 'package:limpiaya/presentation/screens/chat/chat_screen.dart';

class _ChatFalso implements ChatRepository {
  _ChatFalso({this.mensajesDe = const {}});

  final Map<String, List<Mensaje>> mensajesDe;
  final enviados = <String>[];
  final leidos = <String>[];

  @override
  Future<List<Conversacion>> conversaciones() async => const [];

  @override
  Stream<List<Mensaje>> mensajes(String solicitudId) =>
      Stream.value(mensajesDe[solicitudId] ?? const []);

  @override
  Future<void> enviar(String solicitudId, String contenido) async {
    enviados.add(contenido);
  }

  @override
  Future<void> marcarLeidos(String solicitudId) async {
    leidos.add(solicitudId);
  }
}

class _ServiciosFalsos implements ServicioRepository {
  _ServiciosFalsos(this.servicio);

  final ServicioAgendado? servicio;

  @override
  Future<void> elegir(String postulacionId) async {}

  @override
  Future<void> completar(String solicitudId) async {}

  @override
  Future<void> cancelar(String solicitudId, {required String motivo}) async {}

  @override
  Future<List<ServicioAgendado>> misServicios() async => [?servicio];

  @override
  Future<ServicioAgendado?> servicioAgendado(String id) async => servicio;
}

class _SesionFalsa extends SesionNotifier {
  @override
  Future<Sesion?> build() async => const Sesion(
        id: 'c1',
        rol: RolUsuario.cliente,
        nombre: 'María Alejandra',
        perfilCompleto: true,
      );
}

ServicioAgendado _servicio({
  EstadoSolicitud estado = EstadoSolicitud.asignada,
  DateTime? completadaEn,
}) =>
    ServicioAgendado(
      id: 's1',
      estado: estado,
      tipo: TipoLimpieza.profunda,
      zona: 'Los Palos Grandes',
      inicio: DateTime.now(),
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      soyCliente: true,
      contraparteId: 't1',
      contraparteNombre: 'Carmen Pérez',
      completadaEn: completadaEn,
    );

Mensaje _mensaje(int id, String autor, String texto) => Mensaje(
      id: id,
      solicitudId: 's1',
      autorId: autor,
      contenido: texto,
      enviadoEn: DateTime(2026, 11, 10, 9, 30),
    );

Widget _app({
  required ServicioAgendado? servicio,
  required ChatRepository chat,
}) =>
    ProviderScope(
      overrides: [
        servicioRepositoryProvider.overrideWithValue(
          _ServiciosFalsos(servicio),
        ),
        chatRepositoryProvider.overrideWithValue(chat),
        sesionProvider.overrideWith(_SesionFalsa.new),
      ],
      child: MaterialApp(
        theme: AppTheme.claro,
        home: const ChatScreen(solicitudId: 's1'),
      ),
    );

void _pantallaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  testWidgets('HU-38 c2: muestra los dos lados con su fecha y hora',
      (tester) async {
    _pantallaGrande(tester);
    final chat = _ChatFalso(
      mensajesDe: {
        's1': [
          _mensaje(1, 't1', 'Hola, llego a las 8:30.'),
          _mensaje(2, 'c1', 'Perfecto, te espero.'),
        ],
      },
    );
    await tester.pumpWidget(_app(servicio: _servicio(), chat: chat));
    await tester.pumpAndSettle();

    expect(find.text('Chat con Carmen Pérez'), findsOneWidget);
    expect(find.text('Hola, llego a las 8:30.'), findsOneWidget);
    expect(find.text('Perfecto, te espero.'), findsOneWidget);
    expect(find.text('10 nov. · 9:30 a. m.'), findsNWidgets(2));
    // Al abrir, los mensajes de la otra parte quedan leídos.
    expect(chat.leidos, ['s1']);
  });

  testWidgets('HU-38 c3: enviar un mensaje lo guarda y limpia el campo',
      (tester) async {
    _pantallaGrande(tester);
    final chat = _ChatFalso();
    await tester.pumpWidget(_app(servicio: _servicio(), chat: chat));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('campo-mensaje')), 'Voy saliendo');
    await tester.tap(find.byKey(const Key('enviar-mensaje')));
    await tester.pumpAndSettle();

    expect(chat.enviados, ['Voy saliendo']);
    expect(
      tester.widget<TextField>(find.byKey(const Key('campo-mensaje'))).controller!.text,
      isEmpty,
    );
  });

  testWidgets('HU-38: un mensaje vacío no se envía y avisa', (tester) async {
    _pantallaGrande(tester);
    final chat = _ChatFalso();
    await tester.pumpWidget(_app(servicio: _servicio(), chat: chat));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('enviar-mensaje')));
    await tester.pumpAndSettle();

    expect(chat.enviados, isEmpty);
    expect(find.text('Escribe un mensaje antes de enviarlo.'), findsOneWidget);
  });

  testWidgets('HU-38: con el chat cerrado se lee pero no se escribe',
      (tester) async {
    _pantallaGrande(tester);
    final chat = _ChatFalso(
      mensajesDe: {
        's1': [_mensaje(1, 't1', 'Gracias por todo.')],
      },
    );
    await tester.pumpWidget(_app(
      servicio: _servicio(
        estado: EstadoSolicitud.completada,
        completadaEn: DateTime.now().subtract(const Duration(days: 8)),
      ),
      chat: chat,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Gracias por todo.'), findsOneWidget);
    expect(find.byKey(const Key('campo-mensaje')), findsNothing);
    expect(
      find.textContaining('no enviar mensajes nuevos'),
      findsOneWidget,
    );
  });

  testWidgets('HU-38: quien no es parte del servicio no ve el chat',
      (tester) async {
    _pantallaGrande(tester);
    await tester.pumpWidget(
      _app(servicio: null, chat: _ChatFalso()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tienes acceso a este chat.'), findsOneWidget);
    expect(find.byKey(const Key('campo-mensaje')), findsNothing);
  });
}
