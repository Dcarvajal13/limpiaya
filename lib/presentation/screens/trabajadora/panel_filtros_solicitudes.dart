import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../providers/solicitudes_disponibles_provider.dart';

/// Panel "Filtros" de HU-11 (criterio 2): tipo de limpieza, fecha y zonas.
///
/// Los cambios se aplican al instante; no hay botón de "aplicar".
class PanelFiltrosSolicitudes extends ConsumerWidget {
  const PanelFiltrosSolicitudes({super.key, required this.zonas});

  /// Zonas de la trabajadora (las que puede marcar/desmarcar).
  final List<Zona> zonas;

  Future<void> _elegirFecha(BuildContext context, WidgetRef ref) async {
    final hoy = DateTime.now();
    final actual = ref.read(filtroSolicitudesProvider).fecha;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual ?? hoy,
      // Solo hay solicitudes futuras (HU-11 c1).
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Filtrar por fecha',
    );
    if (elegida != null) {
      ref.read(filtroSolicitudesProvider.notifier).elegirFecha(elegida);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final filtro = ref.watch(filtroSolicitudesProvider);
    final notificador = ref.read(filtroSolicitudesProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Filtros', style: textos.titleMedium)),
                if (filtro.hayFiltros)
                  TextButton(
                    onPressed: notificador.limpiar,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Limpiar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Tipo de limpieza', style: textos.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipFiltro(
                  etiqueta: 'Todos',
                  seleccionado: filtro.tipo == null,
                  onTap: () => notificador.elegirTipo(null),
                ),
                for (final tipo in TipoLimpieza.values)
                  _ChipFiltro(
                    etiqueta: tipo.etiqueta,
                    seleccionado: filtro.tipo == tipo,
                    onTap: () => notificador.elegirTipo(tipo),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Fecha', style: textos.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _elegirFecha(context, ref),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      filtro.fecha == null
                          ? 'Cualquier fecha'
                          : Formato.diaCorto(filtro.fecha!),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      alignment: Alignment.centerLeft,
                      side: const BorderSide(color: AppColors.borde),
                      foregroundColor: AppColors.texto,
                    ),
                  ),
                ),
                if (filtro.fecha != null)
                  IconButton(
                    tooltip: 'Quitar fecha',
                    onPressed: () => notificador.elegirFecha(null),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Mis zonas', style: textos.bodySmall),
            const SizedBox(height: 4),
            if (zonas.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Aún no tienes zonas en tu perfil.',
                  style: textos.bodySmall?.copyWith(fontSize: 13),
                ),
              )
            else
              for (final zona in zonas)
                CheckboxListTile(
                  value: !filtro.zonasOcultas.contains(zona.id),
                  onChanged: (_) => notificador.alternarZona(zona.id),
                  title: Text(
                    zona.nombre,
                    style: textos.bodyMedium?.copyWith(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                ),
          ],
        ),
      ),
    );
  }
}

/// Chip de opción: oscuro cuando está elegido, como en el Figma.
class _ChipFiltro extends StatelessWidget {
  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.texto,
      labelStyle: textos.labelMedium?.copyWith(
        fontSize: 13,
        color: seleccionado ? Colors.white : AppColors.texto,
      ),
      side: BorderSide(color: seleccionado ? AppColors.texto : AppColors.borde),
    );
  }
}
