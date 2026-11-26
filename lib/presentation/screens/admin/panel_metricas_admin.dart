import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/metricas_plataforma.dart';
import '../../../domain/services/admin_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/estado_vacio.dart';

/// HU-36 · Métricas de la plataforma: totales del mes, % con postulación y
/// % completado (medición de la hipótesis del MVP).
class PanelMetricasAdmin extends ConsumerStatefulWidget {
  const PanelMetricasAdmin({super.key});

  @override
  ConsumerState<PanelMetricasAdmin> createState() => _PanelMetricasAdminState();
}

class _PanelMetricasAdminState extends ConsumerState<PanelMetricasAdmin> {
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mes = DateTime(hoy.year, hoy.month, 1);
  }

  void _cambiarMes(int delta) {
    setState(() {
      _mes = DateTime(_mes.year, _mes.month + delta, 1);
    });
  }

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  String get _etiquetaMes => '${_meses[_mes.month - 1]} ${_mes.year}';

  @override
  Widget build(BuildContext context) {
    final metricasAsync = ref.watch(metricasPlataformaProvider(_mes));
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.outlined(
              tooltip: 'Mes anterior',
              onPressed: () => _cambiarMes(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 12),
            Text(_etiquetaMes, style: textos.titleLarge),
            const SizedBox(width: 12),
            IconButton.outlined(
              tooltip: 'Mes siguiente',
              onPressed: () => _cambiarMes(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        metricasAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => EstadoVacio(
            icono: Icons.error_outline_rounded,
            titulo: 'No pudimos cargar las métricas',
            mensaje: error is AppException ? error.mensaje : null,
            textoBoton: 'Intentar de nuevo',
            onPressed: () => ref.invalidate(metricasPlataformaProvider(_mes)),
          ),
          data: (m) => _ContenidoMetricas(metricas: m),
        ),
      ],
    );
  }
}

class _ContenidoMetricas extends StatelessWidget {
  const _ContenidoMetricas({required this.metricas});

  final MetricasPlataforma metricas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tarjeta de resumen de la hipótesis del MVP
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primarioClaro,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primario.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primario),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hipótesis del MVP',
                      style: textos.labelLarge?.copyWith(
                        color: AppColors.primarioOscuro,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AdminService.resumenHipotesis(metricas),
                      style: textos.bodyMedium?.copyWith(
                        color: AppColors.primarioOscuro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _TarjetaKpi(
              titulo: 'Solicitudes del mes',
              valor: '${metricas.totalSolicitudes}',
              subtitulo:
                  '${metricas.solicitudesAsignadas} asignadas · ${metricas.solicitudesCanceladas} canceladas',
              icono: Icons.assignment_outlined,
            ),
            _TarjetaKpi(
              titulo: '% con postulación',
              valor: '${metricas.pctConPostulacion.toStringAsFixed(1)} %',
              subtitulo:
                  '${metricas.solicitudesConPostulacion} de ${metricas.totalSolicitudes} solicitudes',
              icono: Icons.how_to_reg_outlined,
              progreso: metricas.pctConPostulacion / 100,
            ),
            _TarjetaKpi(
              titulo: '% completado',
              valor: '${metricas.pctCompletado.toStringAsFixed(1)} %',
              subtitulo:
                  '${metricas.solicitudesCompletadas} servicios completados',
              icono: Icons.task_alt_rounded,
              progreso: metricas.pctCompletado / 100,
            ),
            _TarjetaKpi(
              titulo: 'Usuarios nuevos',
              valor: '${metricas.usuariosNuevos}',
              subtitulo:
                  '${metricas.clientesNuevos} clientes · ${metricas.trabajadorasNuevas} trabajadoras',
              icono: Icons.group_add_outlined,
            ),
            _TarjetaKpi(
              titulo: 'Trabajadoras verificadas',
              valor: '${metricas.trabajadorasVerificadas}',
              subtitulo: 'Activas y disponibles',
              icono: Icons.verified_outlined,
            ),
            _TarjetaKpi(
              titulo: 'Volumen completado',
              valor: '\$${metricas.volumenUsd.toStringAsFixed(2)}',
              subtitulo: 'Total USD en servicios cerrados',
              icono: Icons.payments_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaKpi extends StatelessWidget {
  const _TarjetaKpi({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
    this.progreso,
  });

  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;
  final double? progreso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, color: AppColors.primario, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: textos.labelLarge?.copyWith(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                valor,
                style: textos.headlineLarge?.copyWith(
                  color: AppColors.primarioOscuro,
                ),
              ),
              if (progreso != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso!.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.arena,
                    color: AppColors.primario,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                subtitulo,
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
