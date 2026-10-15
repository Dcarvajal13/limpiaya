import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/solicitud_disponible.dart';

/// Tarjeta de una solicitud disponible (HU-11), igual al Figma W06.
///
/// Muestra: tipo y pago, fecha/hora/duración, zona, método de pago y
/// cuántas trabajadoras ya se postularon. NUNCA muestra la dirección exacta
/// (esa solo la ve la trabajadora elegida).
///
/// TODO(HU-13): al tocar la tarjeta, abrir el detalle de la solicitud.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({super.key, required this.solicitud, this.onTap});

  final SolicitudDisponible solicitud;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      solicitud.tipo.etiqueta,
                      style: textos.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Formato.dinero(solicitud.pagoOfrecido),
                    style: textos.titleLarge?.copyWith(
                      color: AppColors.primario,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Formato.horario(solicitud.inicio, solicitud.horasEstimadas),
                style: textos.bodyMedium?.copyWith(fontSize: 14),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Text(
                solicitud.zona,
                style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${solicitud.metodoPago.etiqueta} · '
                '${Formato.postulantes(solicitud.numPostulantes)}',
                style: textos.bodySmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
