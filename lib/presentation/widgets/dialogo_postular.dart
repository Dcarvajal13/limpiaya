import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/solicitud_disponible.dart';
import '../providers/postular_solicitud_provider.dart';

/// HU-12 · Diálogo para postularse a una solicitud.
///
/// Pide un mensaje corto **opcional** (máximo 300 caracteres, igual que la
/// columna en la base de datos) y envía la postulación. Devuelve `true`
/// cuando quedó registrada; si falla, muestra el mensaje del dominio
/// (ya postulada, choque de horario, sin red…) sin cerrar el diálogo.
class DialogoPostular extends ConsumerStatefulWidget {
  const DialogoPostular({super.key, required this.solicitud});

  final SolicitudDisponible solicitud;

  @override
  ConsumerState<DialogoPostular> createState() => _DialogoPostularState();
}

class _DialogoPostularState extends ConsumerState<DialogoPostular> {
  final _mensaje = TextEditingController();
  String? _error;
  bool _enviando = false;

  @override
  void dispose() {
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    final error = await ref.read(postularSolicitudProvider.notifier).postular(
          solicitudId: widget.solicitud.id,
          mensaje: _mensaje.text,
        );
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

    return AlertDialog(
      title: const Text('Postularme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuéntale al cliente por qué eres buena opción. Es opcional.',
            style: textos.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('campo-mensaje-postulacion'),
            controller: _mensaje,
            maxLength: 300,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_enviando,
            decoration: const InputDecoration(
              labelText: 'Mensaje (opcional)',
              hintText: 'Tengo experiencia con casas grandes…',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              key: const Key('error-postulacion'),
              style: textos.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('enviar-postulacion'),
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar postulación'),
        ),
      ],
    );
  }
}
