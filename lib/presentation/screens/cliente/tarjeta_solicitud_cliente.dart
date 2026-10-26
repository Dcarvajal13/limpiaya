import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/solicitud.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta horizontal de solicitud del cliente (Figma C05).
///
/// Muestra:
/// - Bloque con día y mes en grande a la izquierda.
/// - Insignia de estado + tipo de limpieza ("Limpieza general", etc.).
/// - Día y hora del servicio (ej. "Sábado, 9:00 a. m.").
/// - Zona, duración estimada y monto ("Los Palos Grandes, Chacao · 4 horas · $30").
/// - Postulantes (con ícono rojo/terracota), trabajadora asignada o motivo de cancelación.
/// - Botones de acción a la derecha ("Ver postulantes", "Ver servicio", "Calificar", "Editar").
class TarjetaSolicitudCliente extends StatelessWidget {
  const TarjetaSolicitudCliente({
    super.key,
    required this.solicitud,
    this.onTap,
    this.onEditar,
  });

  final Solicitud solicitud;
  final VoidCallback? onTap;
  final VoidCallback? onEditar;

  TonoInsignia _tono(EstadoSolicitud estado) => switch (estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  void _accion(BuildContext context, String mensaje) {
    if (onTap != null) return onTap!();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;

    final badgeFecha = Container(
      width: 58,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.arena),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            solicitud.inicio.day.toString().padLeft(2, '0'),
            style: textos.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.1,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Formato.mesMayus(solicitud.inicio),
            style: textos.labelSmall?.copyWith(
              color: AppColors.acento,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    final infoCentral = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InsigniaEstado(
              solicitud.estado.etiqueta,
              tono: _tono(solicitud.estado),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Limpieza ${solicitud.tipo.etiqueta.toLowerCase()}',
                style: textos.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.textoSecundario,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          Formato.diaCompletoHora(solicitud.inicio),
          style: textos.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.textoSecundario,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${solicitud.zona} · '
                '${Formato.horas(solicitud.horasEstimadas)} · '
                '${Formato.dinero(solicitud.pagoOfrecido)}',
                style: textos.bodySmall?.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _construirDetalleEstado(context),
      ],
    );

    final acciones = _construirBotones(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      padding: EdgeInsets.all(movil ? 16 : 20),
      child: movil
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badgeFecha,
                    const SizedBox(width: 14),
                    Expanded(child: infoCentral),
                  ],
                ),
                if (acciones != null) ...[
                  const SizedBox(height: 16),
                  acciones,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                badgeFecha,
                const SizedBox(width: 18),
                Expanded(child: infoCentral),
                if (acciones != null) ...[
                  const SizedBox(width: 20),
                  acciones,
                ],
              ],
            ),
    );
  }

  Widget _construirDetalleEstado(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    switch (solicitud.estado) {
      case EstadoSolicitud.publicada:
        if (solicitud.numPostulantes > 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: AppColors.acento,
              ),
              const SizedBox(width: 4),
              Text(
                Formato.postulantes(solicitud.numPostulantes),
                style: textos.bodySmall?.copyWith(
                  color: AppColors.acento,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          );
        }
        return Text(
          'Sin postulantes aún',
          style: textos.bodySmall?.copyWith(fontSize: 13, fontStyle: FontStyle.italic),
        );

      case EstadoSolicitud.asignada:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primarioClaro,
              child: Text(
                'CP',
                style: textos.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primarioOscuro,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Carmen Pérez',
                  style: textos.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '★ 4,9',
                  style: textos.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        );

      case EstadoSolicitud.cancelada:
        return Text(
          'Motivo: ${solicitud.notas ?? 'Cambio de planes'}',
          style: textos.bodySmall?.copyWith(
            fontSize: 12,
            color: AppColors.textoSecundario,
          ),
        );

      case EstadoSolicitud.completada:
        return const SizedBox.shrink();
    }
  }

  Widget? _construirBotones(BuildContext context) {
    final movil = Responsive.esMovil(context);

    switch (solicitud.estado) {
      case EstadoSolicitud.publicada:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              movil ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => _accion(
                context,
                'La revisión de postulaciones estará disponible pronto (HU-13)',
              ),
              style: FilledButton.styleFrom(
                minimumSize: Size(movil ? double.infinity : 150, 44),
                backgroundColor: AppColors.primarioOscuro,
              ),
              child: const Text('Ver postulantes'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                if (onEditar != null) return onEditar!();
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Editar solicitud estará disponible pronto (HU-09)'),
                    ),
                  );
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                foregroundColor: AppColors.primario,
              ),
              child: const Text('Editar'),
            ),
          ],
        );

      case EstadoSolicitud.asignada:
        return FilledButton(
          onPressed: () => _accion(
            context,
            'El seguimiento del servicio estará disponible pronto (HU-16)',
          ),
          style: FilledButton.styleFrom(
            minimumSize: Size(movil ? double.infinity : 150, 44),
            backgroundColor: AppColors.primarioOscuro,
          ),
          child: const Text('Ver servicio'),
        );

      case EstadoSolicitud.completada:
        return OutlinedButton(
          onPressed: () => _accion(
            context,
            'Calificar servicio estará disponible pronto (HU-29)',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(movil ? double.infinity : 120, 44),
            side: const BorderSide(color: AppColors.primario, width: 1.5),
          ),
          child: const Text('Calificar'),
        );

      case EstadoSolicitud.cancelada:
        return null;
    }
  }
}
