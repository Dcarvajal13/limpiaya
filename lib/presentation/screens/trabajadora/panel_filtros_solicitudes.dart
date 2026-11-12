import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/arbol_zonas.dart';
import '../../../domain/services/filtro_solicitudes.dart';
import '../../providers/solicitudes_disponibles_provider.dart';

/// Barra de filtros de HU-11 (criterio 2), igual al Figma W06:
/// "Tipo de limpieza", "Desde la fecha", "Zonas", "Sin mascotas" y "Filtrar".
///
/// El tipo, la fecha y las mascotas se eligen primero y se aplican al tocar
/// "Filtrar". Las zonas se eligen en una ventana agrupada por municipio y se
/// aplican al instante (si solo tiene una zona, el campo no se muestra).
///
/// Feedback del Product Review: en vez de mostrar todas las zonas como
/// chips (mucha carga visual, H8), el campo "Zonas" muestra un resumen.
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

  /// Ventana "Mis zonas": las zonas agrupadas por municipio, con casillas.
  /// Cada cambio se aplica al instante (como los chips de antes).
  Future<void> _elegirZonas(ArbolZonas arbol) {
    return showDialog<void>(
      context: context,
      builder: (dialogo) => Consumer(
        builder: (dialogo, ref, _) {
          final textos = Theme.of(dialogo).textTheme;
          final filtro = ref.watch(filtroSolicitudesProvider);
          final notificador = ref.read(filtroSolicitudesProvider.notifier);

          bool visible(Zona zona) => !filtro.zonasOcultas.contains(zona.id);

          // Deja todas las zonas del grupo visibles (ver = true) u ocultas.
          void poner(Iterable<Zona> grupo, {required bool ver}) {
            for (final zona in grupo) {
              if (visible(zona) != ver) notificador.alternarZona(zona.id);
            }
          }

          return AlertDialog(
            title: const Text('Mis zonas'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Elige en qué zonas quieres ver trabajos.',
                      style: textos.bodySmall
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 8),
                    for (final municipio in arbol.municipios)
                      Builder(
                        builder: (context) {
                          final zonas = arbol.zonasDelMunicipio(municipio);
                          final cuantas = zonas.where(visible).length;
                          final todas = cuantas == zonas.length;
                          return ExpansionTile(
                            key: PageStorageKey('filtro-municipio-$municipio'),
                            shape: const Border(),
                            collapsedShape: const Border(),
                            tilePadding: EdgeInsets.zero,
                            leading: Checkbox(
                              key: Key('filtro-todo-$municipio'),
                              tristate: true,
                              value: cuantas == 0 ? false : (todas ? true : null),
                              onChanged: (_) => poner(zonas, ver: !todas),
                            ),
                            title: Text(
                              municipio,
                              style: textos.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '$cuantas de ${zonas.length} zonas',
                              style: textos.bodySmall?.copyWith(
                                color: cuantas == 0
                                    ? AppColors.textoSecundario
                                    : AppColors.primario,
                              ),
                            ),
                            children: [
                              for (final zona in zonas)
                                CheckboxListTile(
                                  key: Key('filtro-zona-${zona.id}'),
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets.only(left: 24),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  value: visible(zona),
                                  title: Text(zona.nombre),
                                  onChanged: (_) =>
                                      notificador.alternarZona(zona.id),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                key: const Key('filtro-zonas-ver-todas'),
                onPressed: () => poner(widget.zonas, ver: true),
                child: const Text('Ver todas'),
              ),
              FilledButton(
                key: const Key('filtro-zonas-listo'),
                onPressed: () => Navigator.of(dialogo).pop(),
                child: const Text('Listo'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final filtro = ref.watch(filtroSolicitudesProvider);
    final notificador = ref.read(filtroSolicitudesProvider.notifier);
    final movil = Responsive.esMovil(context);
    // Las zonas se agrupan por municipio, como en el perfil.
    final arbol = ArbolZonas(widget.zonas);

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

    // "Zonas": un resumen en vez de todos los chips (H8).
    final mostrarZonas = widget.zonas.length > 1;
    final totalZonas = widget.zonas.length;
    final zonasVisibles = widget.zonas
        .where((z) => !filtro.zonasOcultas.contains(z.id))
        .length;
    final resumenZonas = zonasVisibles == totalZonas
        ? 'Todas mis zonas ($totalZonas)'
        : zonasVisibles == 0
            ? 'Ninguna zona'
            : '$zonasVisibles de $totalZonas zonas';

    final zonas = _Campo(
      etiqueta: 'Zonas',
      child: InkWell(
        key: const Key('filtro-zonas'),
        onTap: () => _elegirZonas(arbol),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: Icon(Icons.place_outlined, size: 18),
            suffixIcon: Icon(Icons.expand_more_rounded, size: 20),
          ),
          child: Text(
            resumenZonas,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textos.bodyMedium?.copyWith(fontSize: 14),
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
              if (mostrarZonas) ...[
                const SizedBox(height: 12),
                zonas,
              ],
              const SizedBox(height: 8),
              Row(children: [mascotas, const Spacer(), boton]),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 4, child: tipo),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: fecha),
                  if (mostrarZonas) ...[
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: zonas),
                  ],
                  const SizedBox(width: 12),
                  mascotas,
                  const SizedBox(width: 12),
                  boton,
                ],
              ),
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