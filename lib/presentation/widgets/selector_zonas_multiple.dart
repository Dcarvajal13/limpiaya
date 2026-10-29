import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/zona.dart';
import '../../domain/services/arbol_zonas.dart';

/// "¿Dónde trabajas?" de la trabajadora (HU-04), ordenado como lista:
/// Municipio → Parroquia → Urbanizaciones (corrección de la revisión).
///
/// - Cada municipio se abre y muestra sus parroquias con sus urbanizaciones.
/// - La casilla del municipio elige o quita todas sus urbanizaciones.
/// - Cada parroquia tiene "Seleccionar todas" / "Quitar todas".
/// - Arriba se ven las urbanizaciones elegidas, con una × para quitarlas.
/// - La barra de búsqueda filtra por urbanización, parroquia o municipio
///   (sin importar acentos) y muestra solo lo que coincide, ya abierto.
class SelectorZonasMultiple extends StatefulWidget {
  const SelectorZonasMultiple({
    super.key,
    required this.zonas,
    required this.seleccionadas,
    required this.onChanged,
  });

  final List<Zona> zonas;
  final Set<int> seleccionadas;
  final ValueChanged<Set<int>> onChanged;

  @override
  State<SelectorZonasMultiple> createState() => _SelectorZonasMultipleState();
}

class _SelectorZonasMultipleState extends State<SelectorZonasMultiple> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Zona> get zonas => widget.zonas;
  Set<int> get seleccionadas => widget.seleccionadas;

  void _cambiar(Iterable<Zona> grupo, {required bool elegir}) {
    final nuevas = {...seleccionadas};
    for (final zona in grupo) {
      if (elegir) {
        nuevas.add(zona.id);
      } else {
        nuevas.remove(zona.id);
      }
    }
    widget.onChanged(nuevas);
  }

  @override
  Widget build(BuildContext context) {
    final arbol = ArbolZonas(zonas);
    final textos = Theme.of(context).textTheme;
    final elegidas = [
      for (final zona in zonas)
        if (seleccionadas.contains(zona.id)) zona,
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          elegidas.isEmpty
              ? 'Abre un municipio para ver sus parroquias y urbanizaciones.'
              : elegidas.length == 1
                  ? 'Elegiste 1 urbanización'
                  : 'Elegiste ${elegidas.length} urbanizaciones',
          key: const Key('resumen-zonas'),
          style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
        ),
        if (elegidas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final zona in elegidas)
                Chip(
                  key: Key('elegida-${zona.id}'),
                  label: Text(zona.nombre),
                  visualDensity: VisualDensity.compact,
                  deleteButtonTooltipMessage: 'Quitar ${zona.nombre}',
                  onDeleted: () => _cambiar([zona], elegir: false),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _BarraBusqueda(
          key: const Key('buscar-zonas'),
          controller: _busqueda,
          pista: 'Busca una urbanización, parroquia o municipio',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borde),
          ),
          clipBehavior: Clip.antiAlias,
          child: _busqueda.text.trim().isEmpty
              ? Column(
                  children: [
                    for (final (i, municipio) in arbol.municipios.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _Municipio(
                        arbol: arbol,
                        municipio: municipio,
                        seleccionadas: seleccionadas,
                        onCambiar: _cambiar,
                      ),
                    ],
                  ],
                )
              : _Resultados(
                  arbol: ArbolZonas(arbol.filtrar(_busqueda.text)),
                  consulta: _busqueda.text.trim(),
                  seleccionadas: seleccionadas,
                  onCambiar: _cambiar,
                ),
        ),
      ],
    );
  }
}

/// Lo que coincide con la búsqueda, ya abierto y agrupado por
/// municipio y parroquia.
class _Resultados extends StatelessWidget {
  const _Resultados({
    required this.arbol,
    required this.consulta,
    required this.seleccionadas,
    required this.onCambiar,
  });

  final ArbolZonas arbol;
  final String consulta;
  final Set<int> seleccionadas;
  final void Function(Iterable<Zona> grupo, {required bool elegir}) onCambiar;

  @override
  Widget build(BuildContext context) {
    if (arbol.estaVacio) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No encontramos "$consulta". Prueba con otro nombre o revisa '
          'cómo está escrito.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textoSecundario,
              ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final municipio in arbol.municipios)
            for (final parroquia in arbol.parroquias(municipio))
              _Parroquia(
                municipio: municipio,
                parroquia: parroquia,
                zonas: arbol.zonas(municipio, parroquia),
                seleccionadas: seleccionadas,
                onCambiar: onCambiar,
                mostrarMunicipio: true,
              ),
        ],
      ),
    );
  }
}

class _Municipio extends StatelessWidget {
  const _Municipio({
    required this.arbol,
    required this.municipio,
    required this.seleccionadas,
    required this.onCambiar,
  });

  final ArbolZonas arbol;
  final String municipio;
  final Set<int> seleccionadas;
  final void Function(Iterable<Zona> grupo, {required bool elegir}) onCambiar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final todas = arbol.zonasDelMunicipio(municipio);
    final cuantas = todas.where((z) => seleccionadas.contains(z.id)).length;
    final todasElegidas = cuantas == todas.length;

    return ExpansionTile(
      key: PageStorageKey('municipio-$municipio'),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Checkbox(
        key: Key('todo-$municipio'),
        tristate: true,
        value: cuantas == 0 ? false : (todasElegidas ? true : null),
        onChanged: (_) => onCambiar(todas, elegir: !todasElegidas),
      ),
      title: Text(
        municipio,
        style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        cuantas == 0
            ? '${todas.length} urbanizaciones'
            : '$cuantas de ${todas.length} elegidas',
        style: textos.bodySmall?.copyWith(
          color: cuantas == 0 ? AppColors.textoSecundario : AppColors.primario,
        ),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final parroquia in arbol.parroquias(municipio))
          _Parroquia(
            municipio: municipio,
            parroquia: parroquia,
            zonas: arbol.zonas(municipio, parroquia),
            seleccionadas: seleccionadas,
            onCambiar: onCambiar,
          ),
      ],
    );
  }
}

class _Parroquia extends StatelessWidget {
  const _Parroquia({
    required this.municipio,
    required this.parroquia,
    required this.zonas,
    required this.seleccionadas,
    required this.onCambiar,
    this.mostrarMunicipio = false,
  });

  final String municipio;
  final String parroquia;
  final List<Zona> zonas;
  final Set<int> seleccionadas;
  final void Function(Iterable<Zona> grupo, {required bool elegir}) onCambiar;

  /// En los resultados de búsqueda no hay municipio abierto arriba: se
  /// muestra junto a la parroquia.
  final bool mostrarMunicipio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final todasElegidas = zonas.every((z) => seleccionadas.contains(z.id));
    final base =
        parroquia == ArbolZonas.sinDato ? parroquia : 'Parroquia $parroquia';
    final titulo = mostrarMunicipio && municipio != ArbolZonas.sinDato
        ? '$municipio · $base'
        : base;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: textos.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ),
              TextButton(
                key: Key('todas-$municipio-$parroquia'),
                onPressed: () => onCambiar(zonas, elegir: !todasElegidas),
                child: Text(todasElegidas ? 'Quitar todas' : 'Seleccionar todas'),
              ),
            ],
          ),
          for (final zona in zonas)
            CheckboxListTile(
              key: Key('zona-${zona.id}'),
              dense: true,
              contentPadding: const EdgeInsets.only(left: 8),
              controlAffinity: ListTileControlAffinity.leading,
              value: seleccionadas.contains(zona.id),
              title: Text(zona.nombre, style: textos.bodyMedium),
              onChanged: (elegir) => onCambiar([zona], elegir: elegir ?? false),
            ),
        ],
      ),
    );
  }
}

/// Campo de búsqueda con lupa y una × para borrar lo escrito.
class _BarraBusqueda extends StatelessWidget {
  const _BarraBusqueda({
    super.key,
    required this.controller,
    required this.pista,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String pista;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: pista,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}
