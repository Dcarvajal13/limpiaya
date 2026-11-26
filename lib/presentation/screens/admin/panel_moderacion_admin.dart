import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/resena_reportada.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/estrellas.dart';
import '../../widgets/insignia_estado.dart';

/// HU-35 · Cola de moderación de reseñas reportadas.
class PanelModeracionAdmin extends ConsumerStatefulWidget {
  const PanelModeracionAdmin({super.key});

  @override
  ConsumerState<PanelModeracionAdmin> createState() =>
      _PanelModeracionAdminState();
}

class _PanelModeracionAdminState extends ConsumerState<PanelModeracionAdmin> {
  bool _guardando = false;

  Future<void> _moderar(ResenaReportada reporte, {required bool ocultar}) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          ocultar ? '¿Ocultar esta reseña?' : '¿Mantener esta reseña visible?',
        ),
        content: Text(
          ocultar
              ? 'La reseña dejará de verse en el perfil y no contará en el promedio.'
              : 'Se cerrará el reporte y la reseña seguirá publicada.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: ocultar ? AppTheme.botonPeligro : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(ocultar ? 'Ocultar reseña' : 'Mantener visible'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    try {
      final service = ref.read(adminServiceProvider);
      if (ocultar) {
        await service.ocultarResena(reporte.reporteId);
      } else {
        await service.mantenerResena(reporte.reporteId);
      }
      ref.invalidate(resenasReportadasProvider);
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            ocultar
                ? 'Reseña ocultada y removida del promedio.'
                : 'Reporte descartado. La reseña sigue visible.',
          ),
        ),
      );
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportesAsync = ref.watch(resenasReportadasProvider);

    return reportesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EstadoVacio(
        icono: Icons.error_outline_rounded,
        titulo: 'No pudimos cargar la cola de moderación',
        mensaje: error is AppException ? error.mensaje : null,
        textoBoton: 'Intentar de nuevo',
        onPressed: () => ref.invalidate(resenasReportadasProvider),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return const EstadoVacio(
            icono: Icons.flag_outlined,
            titulo: 'No hay reseñas reportadas',
            mensaje: 'Cuando un usuario reporte una reseña inapropiada, '
                'aparecerá aquí para tu revisión.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final reporte in lista) ...[
              _TarjetaReporte(
                reporte: reporte,
                guardando: _guardando,
                onOcultar: () => _moderar(reporte, ocultar: true),
                onMantener: () => _moderar(reporte, ocultar: false),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  const _TarjetaReporte({
    required this.reporte,
    required this.guardando,
    required this.onOcultar,
    required this.onMantener,
  });

  final ResenaReportada reporte;
  final bool guardando;
  final VoidCallback onOcultar;
  final VoidCallback onMantener;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Estrellas(valor: reporte.estrellas.toDouble()),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${reporte.autorNombre} → ${reporte.destinatarioNombre}',
                    style: textos.titleSmall,
                  ),
                ),
                const InsigniaEstado('Pendiente', tono: TonoInsignia.ambar),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.fondo,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borde),
              ),
              child: Text(
                (reporte.comentario ?? '').trim().isEmpty
                    ? '(Sin comentario escrito)'
                    : '«${reporte.comentario!.trim()}»',
                style: textos.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.insigniaRojaFondo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reportada por ${reporte.reportadoPorNombre} · '
                '${Formato.diaMesCorto(reporte.creadoEn)}\n'
                'Motivo: ${reporte.motivoReporte}',
                style: textos.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  style: AppTheme.botonPeligro,
                  onPressed: guardando ? null : onOcultar,
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: const Text('Ocultar reseña'),
                ),
                OutlinedButton.icon(
                  onPressed: guardando ? null : onMantener,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Mantener visible'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
