import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/solicitud_disponible.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta de una solicitud disponible (HU-11), igual al Figma W06.
///
/// Muestra: tipo, postulantes, "Recibes $X", fecha y hora, horas estimadas,
/// zona, tamaño de la casa, mascotas y método de pago. NUNCA muestra la
/// dirección exacta (esa solo la ve la trabajadora elegida).
///
/// TODO(HU-13): "Ver solicitud" debe abrir el detalle de la solicitud.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({super.key, required this.solicitud, this.onTap});

  final SolicitudDisponible solicitud;
  final VoidCallback? onTap;

  void _verSolicitud(BuildContext context) {
    if (onTap != null) return onTap!();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('El detalle de la solicitud estará disponible pronto'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final detalle = textos.bodySmall?.copyWith(fontSize: 13);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                InsigniaEstado(solicitud.tipo.etiqueta, tono: TonoInsignia.azul),
                const Spacer(),
                Text(
                  Formato.postulantes(solicitud.numPostulantes),
                  style: textos.bodySmall?.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Recibes ${Formato.dinero(solicitud.pagoOfrecido)}',
              style: textos.headlineSmall?.copyWith(color: AppColors.primario),
            ),
            const SizedBox(height: 10),
            _Linea(
              icono: Icons.calendar_month_outlined,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Formato.diaTarjeta(solicitud.inicio),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.texto,
                      ),
                    ),
                    TextSpan(text: ' · ${Formato.hora(solicitud.inicio)}'),
                  ],
                ),
                style: detalle,
              ),
            ),
            _Linea(
              icono: Icons.schedule,
              child: Text(
                '${Formato.horas(solicitud.horasEstimadas)} estimadas',
                style: detalle,
              ),
            ),
            _Linea(
              icono: Icons.location_on_outlined,
              child: Text('${solicitud.zona}, Caracas', style: detalle),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Dato(
                  icono: Icons.bed_outlined,
                  texto: Formato.habitaciones(solicitud.habitaciones),
                ),
                _Dato(
                  icono: Icons.bathtub_outlined,
                  texto: Formato.banos(solicitud.banos),
                ),
                _Dato(
                  icono: Icons.pets_outlined,
                  texto: solicitud.tieneMascotas ? 'Con mascotas' : 'Sin mascotas',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            _Linea(
              icono: Icons.attach_money,
              child: Text(solicitud.metodoPago.etiqueta, style: detalle),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => _verSolicitud(context),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ver solicitud'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícono gris + texto, una línea de la tarjeta.
class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.child});

  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Recuadro color arena con un dato de la casa ("3 hab.", "2 baños"…).
class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.arena),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: AppColors.texto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.texto,
                ),
          ),
        ],
      ),
    );
  }
}
