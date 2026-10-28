import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/solicitud.dart';

/// Banner verde del inicio del cliente (Figma C05):
/// "Buenos días, María Alejandra" + resumen + botón ámbar "+ Publicar solicitud".
class BannerCliente extends StatelessWidget {
  const BannerCliente({
    super.key,
    required this.saludo,
    required this.resumen,
    required this.onPublicar,
  });

  final String saludo;
  final String resumen;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    final titulo = Text(
      saludo,
      style: (movil ? textos.headlineMedium : textos.headlineLarge)?.copyWith(
        color: Colors.white,
      ),
    );

    final subtitulo = Text(
      resumen,
      style: textos.bodyMedium?.copyWith(
        color: AppColors.verdeSobreOscuro,
        fontStyle: FontStyle.italic,
        fontSize: movil ? 14 : 15,
      ),
    );

    final botonPublicar = FilledButton.icon(
      key: const Key('banner-boton-publicar'),
      onPressed: onPublicar,
      style: AppTheme.botonAmbar.copyWith(
        minimumSize: WidgetStatePropertyAll(
          Size(movil ? double.infinity : 0, 48),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
      icon: const Icon(Icons.add, size: 20, color: AppColors.primarioOscuro),
      label: const Text(
        'Publicar solicitud',
        style: TextStyle(
          color: AppColors.primarioOscuro,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: movil ? 20 : 32,
        vertical: movil ? 24 : 36,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primarioOscuro, AppColors.primario],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -0.6),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (movil)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titulo,
                const SizedBox(height: 8),
                subtitulo,
                const SizedBox(height: 20),
                botonPublicar,
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titulo, const SizedBox(height: 8), subtitulo],
                  ),
                ),
                const SizedBox(width: 24),
                botonPublicar,
              ],
            ),
        ],
      ),
    );
  }
}

/// Fila de 3 tarjetas de métricas (Figma C05):
/// 1. Próximo servicio (ej. "Sáb. 24 oct.")
/// 2. Esperando tu elección (ej. "3 postulantes")
/// 3. Servicios completados (ej. "6 · ★ Tu calificación: 4,9")
class MetricasCliente extends StatelessWidget {
  const MetricasCliente({
    super.key,
    required this.solicitudes,
    this.calificacionPromedio,
  });

  final List<Solicitud> solicitudes;
  final double? calificacionPromedio;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);

    // 1. Próximo servicio (asignada más cercana)
    final ahora = DateTime.now();
    final asignadasFuturas = solicitudes
        .where((s) =>
            s.estado == EstadoSolicitud.asignada && s.inicio.isAfter(ahora))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final proxima = asignadasFuturas.firstOrNull;

    // 2. Con postulaciones pendientes de elección
    final conPostulaciones = solicitudes
        .where((s) =>
            s.estado == EstadoSolicitud.publicada && s.numPostulantes > 0)
        .toList()
      ..sort((a, b) => b.numPostulantes.compareTo(a.numPostulantes));
    final esperando = conPostulaciones.firstOrNull;

    // 3. Completadas
    final completadas = solicitudes
        .where((s) => s.estado == EstadoSolicitud.completada)
        .length;

    final tarjeta1 = _TarjetaMetrica(
      titulo: 'Próximo servicio',
      valor: proxima != null
          ? Formato.diaTarjeta(proxima.inicio)
          : 'Ninguno por ahora',
      subtitulo: proxima != null
          ? (proxima.trabajadoraId != null
              ? 'Servicio asignado'
              : 'En espera de inicio')
          : 'Sin servicios programados',
    );

    final tarjeta2 = _TarjetaMetrica(
      titulo: 'Esperando tu elección',
      valor: esperando != null
          ? Formato.postulantes(esperando.numPostulantes)
          : '0 postulantes',
      subtitulo: esperando != null
          ? 'para el ${Formato.diaDeMes(esperando.inicio)}'
          : 'Sin solicitudes con postulaciones',
    );

    final rating = calificacionPromedio != null
        ? '★ Tu calificación: ${Formato.promedio(calificacionPromedio!)}'
        : '★ Sin calificaciones aún';

    final tarjeta3 = _TarjetaMetrica(
      titulo: 'Servicios completados',
      valor: '$completadas',
      subtitulo: rating,
    );

    if (movil) {
      return Column(
        children: [
          tarjeta1,
          const SizedBox(height: 12),
          tarjeta2,
          const SizedBox(height: 12),
          tarjeta3,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: tarjeta1),
        const SizedBox(width: 16),
        Expanded(child: tarjeta2),
        const SizedBox(width: 16),
        Expanded(child: tarjeta3),
      ],
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  const _TarjetaMetrica({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
  });

  final String titulo;
  final String valor;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: textos.bodySmall?.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            valor,
            style: textos.titleLarge?.copyWith(
              color: AppColors.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: textos.bodySmall?.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
