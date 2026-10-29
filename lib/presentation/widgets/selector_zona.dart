import 'package:flutter/material.dart';

import '../../domain/entities/zona.dart';
import '../../domain/services/arbol_zonas.dart';

/// Elige UNA urbanización en tres pasos: Municipio → Parroquia →
/// Urbanización (corrección de la revisión).
///
/// Lo usan el perfil del cliente (HU-05) y publicar/editar una solicitud
/// (HU-07, HU-09). Si un municipio tiene una sola parroquia (Chacao,
/// El Hatillo), se elige sola para ahorrar un paso.
///
/// Arriba hay una barra de búsqueda: al escribir "merce" sugiere
/// "Las Mercedes · Baruta" y al tocarla completa los tres pasos de una vez.
///
/// El valor es el id de la zona; mientras falte algún paso es `null`.
class SelectorZona extends StatefulWidget {
  const SelectorZona({
    super.key,
    required this.zonas,
    required this.valor,
    required this.onChanged,
    this.validator,
  });

  final List<Zona> zonas;
  final int? valor;
  final ValueChanged<int?> onChanged;

  /// Validación del último paso (por ejemplo, "Elige tu zona").
  final FormFieldValidator<int>? validator;

  @override
  State<SelectorZona> createState() => _SelectorZonaState();
}

class _SelectorZonaState extends State<SelectorZona> {
  late ArbolZonas _arbol;
  String? _municipio;
  String? _parroquia;

  final _busqueda = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _busqueda.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Sugerencia elegida en la búsqueda: completa municipio, parroquia y
  /// urbanización de una vez.
  void _elegirSugerencia(Zona zona) {
    setState(() => _ubicar(zona.id));
    _busqueda.clear();
    _foco.unfocus();
    widget.onChanged(zona.id);
  }

  @override
  void initState() {
    super.initState();
    _arbol = ArbolZonas(widget.zonas);
    _ubicar(widget.valor);
  }

  @override
  void didUpdateWidget(covariant SelectorZona anterior) {
    super.didUpdateWidget(anterior);
    if (!identical(anterior.zonas, widget.zonas)) {
      _arbol = ArbolZonas(widget.zonas);
    }
    // Si el valor llega de afuera (perfil guardado, solicitud a editar),
    // se muestran su municipio y su parroquia.
    if (widget.valor != null && widget.valor != anterior.valor) {
      _ubicar(widget.valor);
    } else if (_municipio == null && widget.valor != null) {
      _ubicar(widget.valor);
    }
  }

  void _ubicar(int? id) {
    final ubicacion = _arbol.ubicacion(id);
    if (ubicacion == null) return;
    _municipio = ubicacion.$1;
    _parroquia = ubicacion.$2;
  }

  void _elegirMunicipio(String municipio) {
    if (municipio == _municipio) return;
    final parroquias = _arbol.parroquias(municipio);
    setState(() {
      _municipio = municipio;
      _parroquia = parroquias.length == 1 ? parroquias.first : null;
    });
    if (widget.valor != null) widget.onChanged(null);
  }

  void _elegirParroquia(String parroquia) {
    if (parroquia == _parroquia) return;
    setState(() => _parroquia = parroquia);
    if (widget.valor != null) widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final municipio = _municipio;
    final parroquia = _parroquia;
    final parroquias =
        municipio == null ? const <String>[] : _arbol.parroquias(municipio);
    final urbanizaciones = municipio == null || parroquia == null
        ? const <Zona>[]
        : _arbol.zonas(municipio, parroquia);
    final valor =
        urbanizaciones.any((z) => z.id == widget.valor) ? widget.valor : null;

    // Cada lista se vuelve a crear cuando cambia el paso anterior, para que
    // no se quede mostrando una opción que ya no existe.
    final campoMunicipio = KeyedSubtree(
      key: ValueKey('municipio-$municipio'),
      child: DropdownButtonFormField<String>(
        key: const Key('zona-municipio'),
        initialValue: municipio,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Municipio'),
        hint: const Text('Elige el municipio'),
        items: [
          for (final m in _arbol.municipios)
            DropdownMenuItem(value: m, child: _Opcion(m)),
        ],
        onChanged: (m) {
          if (m != null) _elegirMunicipio(m);
        },
      ),
    );

    final campoParroquia = KeyedSubtree(
      key: ValueKey('parroquia-$municipio-$parroquia'),
      child: DropdownButtonFormField<String>(
        key: const Key('zona-parroquia'),
        initialValue: parroquia,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Parroquia'),
        hint: const Text('Elige la parroquia'),
        disabledHint: const Text('Primero el municipio'),
        items: [
          for (final p in parroquias)
            DropdownMenuItem(value: p, child: _Opcion(p)),
        ],
        onChanged: parroquias.isEmpty
            ? null
            : (p) {
                if (p != null) _elegirParroquia(p);
              },
      ),
    );

    final campoUrbanizacion = KeyedSubtree(
      key: ValueKey('urbanizacion-$municipio-$parroquia-$valor'),
      child: DropdownButtonFormField<int>(
        key: const Key('zona-urbanizacion'),
        initialValue: valor,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Urbanización'),
        hint: const Text('Elige la urbanización'),
        disabledHint: const Text('Primero la parroquia'),
        items: [
          for (final z in urbanizaciones)
            DropdownMenuItem(value: z.id, child: _Opcion(z.nombre)),
        ],
        onChanged: urbanizaciones.isEmpty ? null : widget.onChanged,
        validator: widget.validator,
      ),
    );

    return LayoutBuilder(
      builder: (context, restricciones) {
        final busqueda = _Busqueda(
          arbol: _arbol,
          controller: _busqueda,
          foco: _foco,
          ancho: restricciones.maxWidth,
          onElegir: _elegirSugerencia,
        );

        final pasos = restricciones.maxWidth >= 620
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campoMunicipio),
                  const SizedBox(width: 12),
                  Expanded(child: campoParroquia),
                  const SizedBox(width: 12),
                  Expanded(child: campoUrbanizacion),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  campoMunicipio,
                  const SizedBox(height: 12),
                  campoParroquia,
                  const SizedBox(height: 12),
                  campoUrbanizacion,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [busqueda, const SizedBox(height: 12), pasos],
        );
      },
    );
  }
}

/// Texto de una opción que se corta con "…" si no cabe.
class _Opcion extends StatelessWidget {
  const _Opcion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto, overflow: TextOverflow.ellipsis, maxLines: 1);
}

/// Barra de búsqueda con sugerencias debajo (urbanización, municipio y
/// parroquia). No se ve como un paso más: es un atajo.
class _Busqueda extends StatelessWidget {
  const _Busqueda({
    required this.arbol,
    required this.controller,
    required this.foco,
    required this.ancho,
    required this.onElegir,
  });

  final ArbolZonas arbol;
  final TextEditingController controller;
  final FocusNode foco;
  final double ancho;
  final ValueChanged<Zona> onElegir;

  static String _ubicacion(Zona zona) {
    final partes = [
      if (zona.municipio.isNotEmpty) zona.municipio,
      if (zona.parroquia.isNotEmpty) 'Parroquia ${zona.parroquia}',
    ];
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return RawAutocomplete<Zona>(
      textEditingController: controller,
      focusNode: foco,
      displayStringForOption: (zona) => zona.nombre,
      optionsBuilder: (valor) => arbol.filtrar(valor.text).take(8),
      onSelected: onElegir,
      fieldViewBuilder: (context, controller, foco, alEnviar) => TextField(
        key: const Key('buscar-zona'),
        controller: controller,
        focusNode: foco,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => alEnviar(),
        decoration: const InputDecoration(
          hintText: 'Busca tu urbanización (por ejemplo, Las Mercedes)',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      optionsViewBuilder: (context, elegir, opciones) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 300, maxWidth: ancho),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final zona in opciones)
                  ListTile(
                    key: Key('opcion-zona-${zona.id}'),
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(zona.nombre, style: textos.bodyMedium),
                    subtitle: _ubicacion(zona).isEmpty
                        ? null
                        : Text(_ubicacion(zona), style: textos.bodySmall),
                    onTap: () => elegir(zona),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
