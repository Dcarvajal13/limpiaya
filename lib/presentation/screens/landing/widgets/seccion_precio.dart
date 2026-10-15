import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import 'comunes.dart';

/// "Precio claro": el visitante mueve el monto y ve cuánto recibe la
/// trabajadora, la tarifa de LimpiaYa y el total.
class SeccionPrecio extends StatefulWidget {
  const SeccionPrecio({super.key});

  @override
  State<SeccionPrecio> createState() => _SeccionPrecioState();
}

class _SeccionPrecioState extends State<SeccionPrecio> {
  double _pago = 30;

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MedidasLanding.dosColumnas(context);

    final izquierda = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion(
          antetitulo: 'Precio claro',
          titulo: 'Tú decides cuánto ofrecer.',
          texto: 'La trabajadora ve exactamente cuánto recibe. '
              'Para ella, LimpiaYa es gratis.',
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '¿Cuánto ofreces?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '\$${_pago.round()}',
              style: AppFonts.titulos(
                const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primario,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _pago,
          min: 18,
          max: 60,
          divisions: 42,
          label: '\$${_pago.round()}',
          semanticFormatterCallback: (v) => '${v.round()} dólares',
          onChanged: (v) => setState(() => _pago = v.roundToDouble()),
        ),
      ],
    );

    final recibo = _Recibo(pago: _pago);

    return FranjaLanding(
      child: dosColumnas
          ? Row(
              children: [
                Expanded(flex: 12, child: izquierda),
                const SizedBox(width: 100),
                Expanded(flex: 8, child: recibo),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [izquierda, const SizedBox(height: 20), recibo],
            ),
    );
  }
}

class _Recibo extends StatelessWidget {
  const _Recibo({required this.pago});

  final double pago;

  /// 30 → "$30,00" (con coma decimal, como se escribe en Venezuela).
  static String _dinero(double monto) =>
      '\$${monto.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tarifa = pago * AppConstants.comisionLimpiaYa;
    final porcentaje = (AppConstants.comisionLimpiaYa * 100).round();

    Widget fila(String concepto, double monto, {bool total = false}) {
      final estilo = total
          ? textos.titleMedium?.copyWith(fontSize: 20)
          : textos.bodyMedium;
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          children: [
            Expanded(child: Text(concepto, style: estilo)),
            const SizedBox(width: 16),
            Text(_dinero(monto), style: estilo?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RESUMEN DEL PAGO',
              style: textos.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.textoSecundario,
              ),
            ),
            fila('Pago a la trabajadora', pago),
            fila('Tarifa LimpiaYa ($porcentaje %)', tarifa),
            const Padding(
              padding: EdgeInsets.only(top: 22),
              child: Divider(height: 1),
            ),
            fila('Total', pago + tarifa, total: true),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarioClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: LineaConIcono(
                icono: Icons.check_rounded,
                texto: 'El pago se hace directo a la trabajadora.',
                estilo: textos.bodySmall?.copyWith(
                  color: AppColors.primario,
                  fontWeight: FontWeight.w600,
                ),
                espacio: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
