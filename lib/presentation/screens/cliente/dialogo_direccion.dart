import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../../domain/entities/direccion_guardada.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/direcciones_service.dart';
import '../../providers/direcciones_provider.dart';
import '../../widgets/selector_zona.dart';

/// Agregar una dirección guardada, o editar [actual] si viene.
///
/// [existentes] son las que ya tiene el cliente (para no repetir nombres).
/// Devuelve true si se guardó.
Future<bool> mostrarDialogoDireccion(
  BuildContext context, {
  required List<Zona> zonas,
  required List<DireccionGuardada> existentes,
  DireccionGuardada? actual,
}) async {
  final guardada = await showDialog<bool>(
    context: context,
    builder: (context) => DialogoDireccion(
      zonas: zonas,
      existentes: existentes,
      actual: actual,
    ),
  );
  return guardada ?? false;
}

class DialogoDireccion extends ConsumerStatefulWidget {
  const DialogoDireccion({
    super.key,
    required this.zonas,
    required this.existentes,
    this.actual,
  });

  final List<Zona> zonas;
  final List<DireccionGuardada> existentes;
  final DireccionGuardada? actual;

  @override
  ConsumerState<DialogoDireccion> createState() => _DialogoDireccionState();
}

class _DialogoDireccionState extends ConsumerState<DialogoDireccion> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(
    text: widget.actual?.nombre ??
        DireccionesService.nombreSugerido(widget.existentes),
  );
  late final _direccion =
      TextEditingController(text: widget.actual?.direccion ?? '');
  late final _referencia =
      TextEditingController(text: widget.actual?.puntoReferencia ?? '');
  late int? _zonaId = widget.actual?.zonaId;

  bool _guardando = false;
  bool _intentoEnviar = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    _referencia.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _intentoEnviar = true;
      _error = null;
    });
    final valido = _formKey.currentState?.validate() ?? false;
    final zonaId = _zonaId;
    if (!valido || zonaId == null) return;

    setState(() => _guardando = true);
    final error = await ref.read(direccionesProvider.notifier).guardar(
          id: widget.actual?.id,
          nombre: _nombre.text,
          zonaId: zonaId,
          direccion: _direccion.text,
          puntoReferencia: _referencia.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final editando = widget.actual != null;

    return AlertDialog(
      title: Text(editando ? 'Editar dirección' : 'Nueva dirección'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          autovalidateMode: _intentoEnviar
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('direccion-nombre'),
                  controller: _nombre,
                  maxLength: DireccionesService.largoNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Casa, Trabajo, Casa de mi mamá…',
                    counterText: '',
                  ),
                  validator: (v) => DireccionesService.validarNombre(
                    v,
                    widget.existentes,
                    id: widget.actual?.id,
                  ),
                ),
                const SizedBox(height: 16),
                SelectorZona(
                  zonas: widget.zonas,
                  valor: _zonaId,
                  onChanged: (id) => setState(() => _zonaId = id),
                  validator: (_) => _zonaId == null ? 'Elige la zona' : null,
                ),
                if (_intentoEnviar && _zonaId == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Elige municipio, parroquia y urbanización',
                      style: textos.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('direccion-texto'),
                  controller: _direccion,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Av. Francisco de Miranda, Edificio…',
                  ),
                  validator: Validadores.direccion,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referencia,
                  decoration: const InputDecoration(
                    labelText: 'Punto de referencia (opcional)',
                    hintText: 'Al lado del farmatodo',
                  ),
                  validator: Validadores.maximo(200),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppColors.textoSecundario,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Solo la ve la trabajadora que elijas.',
                        style: textos.bodySmall
                            ?.copyWith(color: AppColors.textoSecundario),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    key: const Key('error-direccion'),
                    style: textos.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('guardar-direccion'),
          onPressed: _guardando ? null : _guardar,
          child: Text(editando ? 'Guardar cambios' : 'Guardar dirección'),
        ),
      ],
    );
  }
}
