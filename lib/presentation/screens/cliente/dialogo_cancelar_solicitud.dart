import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/solicitud.dart';
import '../../../domain/services/solicitud_service.dart';

/// Respuesta del diálogo cuando el cliente confirma la cancelación.
class CancelacionConfirmada {
  const CancelacionConfirmada(this.motivo);

  /// Motivo elegido, o null si no eligió ninguno.
  final String? motivo;
}

/// HU-10 · Confirmación antes de cancelar (H5 del taller: diálogo antes de
/// una acción que no se puede deshacer). Devuelve null si elige "No" (c2).
Future<CancelacionConfirmada?> mostrarDialogoCancelarSolicitud(
  BuildContext context,
  Solicitud solicitud,
) {
  return showDialog<CancelacionConfirmada>(
    context: context,
    builder: (context) => _DialogoCancelar(solicitud: solicitud),
  );
}

class _DialogoCancelar extends StatefulWidget {
  const _DialogoCancelar({required this.solicitud});

  final Solicitud solicitud;

  @override
  State<_DialogoCancelar> createState() => _DialogoCancelarState();
}

class _DialogoCancelarState extends State<_DialogoCancelar> {
  String? _motivo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final postulantes = widget.solicitud.numPostulantes;

    return AlertDialog(
      title: const Text('¿Cancelar esta solicitud?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La solicitud del ${Formato.diaDeMes(widget.solicitud.inicio)} '
              'dejará de verse en la lista de las trabajadoras.',
              style: textos.bodyMedium,
            ),
            if (postulantes > 0) ...[
              const SizedBox(height: 8),
              Text(
                postulantes == 1
                    ? 'La trabajadora que se postuló verá que la cancelaste.'
                    : 'Las $postulantes trabajadoras que se postularon verán '
                        'que la cancelaste.',
                style: textos.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Text('Motivo (opcional)', style: textos.titleSmall),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: _motivo,
              hint: const Text('Selecciona un motivo'),
              items: [
                for (final motivo in SolicitudService.motivosCancelacion)
                  DropdownMenuItem(value: motivo, child: Text(motivo)),
              ],
              onChanged: (valor) => setState(() => _motivo = valor),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('No'),
        ),
        FilledButton(
          style: AppTheme.botonPeligro,
          onPressed: () =>
              Navigator.of(context).pop(CancelacionConfirmada(_motivo)),
          child: const Text('Sí, cancelar'),
        ),
      ],
    );
  }
}
