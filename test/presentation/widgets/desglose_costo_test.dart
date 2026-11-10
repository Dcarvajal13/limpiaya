import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/theme/app_fonts.dart';
import 'package:limpiaya/core/theme/app_theme.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/presentation/screens/cliente/tarjeta_solicitud_cliente.dart';
import 'package:limpiaya/presentation/widgets/desglose_costo.dart';

void main() {
  setUpAll(() => AppFonts.usarGoogleFonts = false);

  group('HU-52 · texto del desglose', () {
    test('pago entero', () {
      expect(
        DesgloseCosto.texto(30),
        r'Pagas $33 en total: $30 para la trabajadora + $3 de tarifa LimpiaYa',
      );
    });

    test('con centavos', () {
      expect(
        DesgloseCosto.texto(25),
        r'Pagas $27.50 en total: $25 para la trabajadora + $2.50 de tarifa '
        'LimpiaYa',
      );
    });
  });

  testWidgets('HU-52 c3: la tarjeta de Mis solicitudes muestra el desglose',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TarjetaSolicitudCliente(
              solicitud: Solicitud(
                id: 's1',
                clienteId: 'c1',
                estado: EstadoSolicitud.publicada,
                tipo: TipoLimpieza.general,
                zonaId: 1,
                zona: 'Petare',
                inicio: DateTime(2026, 11, 14, 9),
                horasEstimadas: 4,
                pagoOfrecido: 30,
                metodoPago: MetodoPago.pagoMovil,
                numPostulantes: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('desglose-s1')), findsOneWidget);
    expect(find.text(DesgloseCosto.texto(30)), findsOneWidget);
  });
}
