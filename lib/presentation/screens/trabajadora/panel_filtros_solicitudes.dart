import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/filtro_solicitudes.dart';
import '../../providers/solicitudes_disponibles_provider.dart';

/// Barra de filtros de HU-11 (criterio 2), igual al Figma W06:
/// "Tipo de limpieza", "Desde la fecha", "Sin mascotas" y el botón "Filtrar".
///
/// El tipo, la fecha y las mascotas se eligen primero y se aplican al tocar
/// "Filtrar". Debajo están las zonas de la trabajadora como chips: esas se
/// aplican al instante (si solo tiene una zona, no se muestran).
class PanelFiltrosSolicitudes extends ConsumerStatefulWidget {
  const PanelFiltrosSolicitudes({super.key, required this.zonas});

  /// Zonas de la trabajadora (las que puede marcar/desmarcar).
  final List<Zona> zonas;

  @override
  ConsumerState<PanelFiltrosSolicitudes> createState() =>
      _PanelFiltrosSolicitudesState();
}

class _PanelFiltrosSolicitudesState
    extends ConsumerState<PanelFiltrosSolicitudes> {
  // Lo elegido pero todavía no aplicado con "Filtrar".
  TipoLimpieza? _tipo;
  DateTime? _fecha;
  bool _sinMascotas = false;

  @override
  void initState() {
    super.initState();
    _copiar(ref.read(filtroSolicitudesProvider));
  }

  void _copiar(FiltroSolicitudes filtro) {
    _tipo = filtro.tipo;
    _fecha = filtro.fecha;
    _sinMascotas = filtro.sinMascotas;
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      // Solo hay solicitudes futuras (HU-11 c1).
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
      helpText: 'Desde la fecha',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _filtrar() {
    ref.read(filtroSolicitudesProvider.notifier).aplicar(
          tipo: _tipo,
          fecha: _fecha,
          sinMascotas: _sinMascotas,
        );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final filtro = ref.watch(filtroSolicitudesProvider);
    final notificador = ref.read(filtroSolicitudesProvider.notifier);
    final movil = Responsive.esMovil(context);

    // Si los filtros cambian desde fuera ("Quitar filtros"), el formulario
    // vuelve a mostrar lo que está aplicado.
    ref.listen(filtroSolicitudesProvider, (_, nuevo) {
      setState(() => _copiar(nuevo));
    });

    final tipo = _Campo(
      etiqueta: 'Tipo de limpieza',
      child: DropdownButtonFormField<TipoLimpieza?>(
        key: ValueKey('filtro-tipo-$_tipo'),
        initialValue: _tipo,
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        style: textos.bodyMedium?.copyWith(fontSize: 14),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos')),
          for (final t in TipoLimpieza.values)
            DropdownMenuItem(value: t, child: Text(t.etiqueta)),
        ],
        onChanged: (valor) => setState(() => _tipo = valor),
      ),
    );

    final fecha = _Campo(
      etiqueta: 'Desde la fecha',
      child: InkWell(
        key: const Key('filtro-fecha'),
        onTap: _elegirFecha,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: _fecha == null
                ? const Icon(Icons.calendar_today_outlined, size: 18)
                : IconButton(
                    tooltip: 'Quitar fecha',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _fecha = null),
                  ),
          ),
          child: Text(
            _fecha == null ? 'dd/mm/aaaa' : Formato.fechaNumerica(_fecha!),
            style: textos.bodyMedium?.copyWith(
              fontSize: 14,
              color: _fecha == null
                  ? AppColors.textoSecundario
                  : AppColors.texto,
            ),
          ),
        ),
      ),
    );

    final mascotas = InkWell(
      onTap: () => setState(() => _sinMascotas = !_sinMascotas),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                key: const Key('filtro-sin-mascotas'),
                value: _sinMascotas,
                onChanged: (valor) =>
                    setState(() => _sinMascotas = valor ?? false),
              ),
            ),
            const SizedBox(width: 4),
            Text('Sin mascotas', style: textos.bodySmall?.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );

    final boton = OutlinedButton.icon(
      key: const Key('boton-filtrar'),
      onPressed: _filtrar,
      icon: const Icon(Icons.search, size: 20),
      label: const Text('Filtrar'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(96, 46)),
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(movil ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movil) ...[
              tipo,
              const SizedBox(height: 12),
              fecha,
              const SizedBox(height: 8),
              Row(children: [mascotas, const Spacer(), boton]),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 5, child: tipo),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: fecha),
                  const SizedBox(width: 12),
                  mascotas,
                  const Spacer(flex: 2),
                  boton,
                ],
              ),
            if (widget.zonas.length > 1) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Mis zonas:', style: textos.bodySmall?.copyWith(fontSize: 13)),
                  for (final zona in widget.zonas)
                    FilterChip(
                      label: Text(zona.nombre),
                      labelStyle: textos.labelMedium?.copyWith(fontSize: 13),
                      selected: !filtro.zonasOcultas.contains(zona.id),
                      onSelected: (_) => notificador.alternarZona(zona.id),
                    ),
                ],
              ),
            ],
            if (filtro.hayFiltros)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: notificador.limpiar,
                  style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
                  child: const Text('Limpiar filtros'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta pequeña arriba y el campo debajo (como `CampoTexto`).
class _Campo extends StatelessWidget {
  const _Campo({required this.etiqueta, required this.child});

  final String etiqueta;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
