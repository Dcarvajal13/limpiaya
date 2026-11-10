import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../domain/services/solicitud_service.dart';

/// HU-52 c3 · Desglose del costo en una línea, para las tarjetas y el
/// resumen de una solicitud ya publicada: el mismo cálculo que se ve al
/// publicarla (SolicitudService.tarifa y total).
///
/// "Pagas $33 en total: $30 para la trabajadora + $3 de tarifa LimpiaYa"
class DesgloseCosto extends StatelessWidget {
  const DesgloseCosto({super.key, required this.pago});

  /// Lo que recibe la trabajadora, en USD.
  final double pago;

  static String texto(double pago) =>
      'Pagas ${Formato.dinero(SolicitudService.total(pago))} en total: '
      '${Formato.dinero(pago)} para la trabajadora + '
      '${Formato.dinero(SolicitudService.tarifa(pago))} de tarifa LimpiaYa';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 16,
            color: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            texto(pago),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
          ),
        ),
      ],
    );
  }
}
