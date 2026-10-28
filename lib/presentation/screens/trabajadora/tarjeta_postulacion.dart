import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_postulacion.dart';
import '../../../domain/entities/postulacion.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta de una postulación en "Mis servicios" (HU-13, Figma W07 - Postulaciones).
///
/// Diseño horizontal idéntico al Figma:
/// - Insignia a la izquierda: Pendiente, Aceptada, No seleccionada o Solicitud cancelada.
/// - Texto: Día/mes + Tipo + Zona (ej. "17 oct. · General · Los Palos Grandes").
/// - Monto: "Recibes $X".
/// - A la derecha:
///   - Pendiente: "Retirar postulación" (HU-26, con confirmación en la
///     pantalla).
///   - Aceptada: "Ver servicio" (HU-13 c3, lleva al servicio agendado).
///   - No seleccionada / Cancelada: sin botón.
class TarjetaPostulacion extends StatelessWidget {
  const TarjetaPostulacion({
    super.key,
    required this.postulacion,
    this.onTap,
    this.onRetirar,
  });

  final Postulacion postulacion;
  final VoidCallback? onTap;
  final VoidCallback? onRetirar;

  TonoInsignia get _tono => switch (postulacion.estado) {
        EstadoPostulacion.pendiente => TonoInsignia.ambar,
        EstadoPostulacion.aceptada => TonoInsignia.verde,
        EstadoPostulacion.noSeleccionada => TonoInsignia.gris,
        EstadoPostulacion.retirada => TonoInsignia.gris,
        EstadoPostulacion.solicitudCancelada => TonoInsignia.rojo,
      };

  void _accionRetirar(BuildContext context) {
    if (onRetirar != null) return onRetirar!();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir la retirada de la postulación'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;

    final badge = InsigniaEstado(postulacion.estado.etiqueta, tono: _tono);

    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${Formato.diaMesCorto(postulacion.inicio)} · '
          '${postulacion.tipo.etiqueta} · '
          '${postulacion.zona}',
          style: textos.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: movil ? 15 : 16,
            color: AppColors.texto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Recibes ${Formato.dinero(postulacion.pagoOfrecido)}',
          style: textos.bodyMedium?.copyWith(
            color: AppColors.textoSecundario,
            fontSize: 14,
          ),
        ),
      ],
    );

    Widget? accion;
    if (postulacion.estado == EstadoPostulacion.pendiente) {
      accion = TextButton(
        key: Key('retirar-${postulacion.id}'),
        onPressed: () => _accionRetirar(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primario,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text('Retirar postulación'),
      );
    } else if (postulacion.estado == EstadoPostulacion.aceptada) {
      accion = FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primario,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: const Text('Ver servicio'),
      );
    }

    final esAceptada = postulacion.estado == EstadoPostulacion.aceptada;

    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Al tocar una postulación aceptada también lleva al servicio agendado (criterio 3).
        onTap: esAceptada ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: movil ? 16 : 24,
            vertical: movil ? 14 : 18,
          ),
          child: movil
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        badge,
                        const SizedBox(width: 12),
                        Expanded(child: datos),
                      ],
                    ),
                    if (accion != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: accion,
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    badge,
                    const SizedBox(width: 20),
                    Expanded(child: datos),
                    if (accion != null) ...[
                      const SizedBox(width: 16),
                      accion,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
