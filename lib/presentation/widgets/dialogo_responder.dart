import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/perfil_publico.dart';
import '../../domain/services/respuesta_service.dart';
import '../providers/mi_reputacion_provider.dart';
import 'estrellas.dart';

/// HU-31 · Abre el diálogo para responder (o editar la respuesta de) una
/// reseña. Devuelve `true` si la respuesta quedó publicada.
Future<bool?> mostrarDialogoResponder(
  BuildContext context, {
  required ResenaPublica resena,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DialogoResponder(resena: resena),
  );
}

/// Diálogo con la reseña arriba y el campo de la respuesta.
///
/// c3 · El contador muestra el límite de 300 caracteres. Se puede escribir
/// de más para no cortar el texto sin avisar, pero al presionar "Publicar"
/// aparece el mensaje y no se publica.
class DialogoResponder extends ConsumerStatefulWidget {
  const DialogoResponder({super.key, required this.resena});

  final ResenaPublica resena;

  @override
  ConsumerState<DialogoResponder> createState() => _DialogoResponderState();
}

class _DialogoResponderState extends ConsumerState<DialogoResponder> {
  late final TextEditingController _texto =
      TextEditingController(text: widget.resena.respuesta ?? '');
  String? _error;
  bool _enviando = false;

  bool get _editando => widget.resena.tieneRespuesta;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    final id = widget.resena.id;
    if (id == null) {
      setState(() => _error = RespuestaService.mensajeError);
      return;
    }

    final invalida = RespuestaService.validar(_texto.text);
    if (invalida != null) {
      setState(() => _error = invalida);
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await ref
        .read(responderResenaProvider.notifier)
        .responder(calificacionId: id, texto: _texto.text);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final resena = widget.resena;

    return AlertDialog(
      title: Text(_editando ? 'Editar mi respuesta' : 'Responder a la reseña'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // La reseña que se está respondiendo.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fondo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Estrellas(valor: resena.estrellas.toDouble(), tamano: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resena.autorNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    if (resena.comentario != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '“${resena.comentario}”',
                        style: textos.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('campo-respuesta'),
                controller: _texto,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: RespuestaService.maxCaracteres,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: 'Tu respuesta',
                  hintText: 'Por ejemplo: ¡Gracias! Fue un gusto trabajar en '
                      'tu casa.',
                  alignLabelWithHint: true,
                  errorText: _error,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _editando
                    ? 'Al guardar, tu respuesta anterior se reemplaza.'
                    : 'Tu respuesta se verá debajo de la reseña en tu perfil. '
                        'Podrás editarla después.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancelar-respuesta'),
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('publicar-respuesta'),
          onPressed: _enviando ? null : _publicar,
          child: Text(_editando ? 'Guardar cambios' : 'Publicar'),
        ),
      ],
    );
  }
}
