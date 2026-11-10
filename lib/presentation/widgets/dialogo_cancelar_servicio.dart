import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formato.dart';
import '../../domain/services/servicio_service.dart';

/// HU-28 · Confirmación antes de cancelar un servicio asignado. La usan el
/// cliente (Mis solicitudes) y la trabajadora (Mis servicios).
///
/// Devuelve el motivo elegido, o `null` si eligió "No" y no cambia nada.
/// c2: sin motivo no deja confirmar y muestra "Elige un motivo".
Future<String?> mostrarDialogoCancelarServicio(
  BuildContext context, {
  required DateTime inicio,
  required List<String> motivos,
  required String otraParte,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DialogoCancelarServicio(
      inicio: inicio,
      motivos: motivos,
      otraParte: otraParte,
    ),
  );
}

class _DialogoCancelarServicio extends StatefulWidget {
  const _DialogoCancelarServicio({
    required this.inicio,
    required this.motivos,
    required this.otraParte,
  });

  final DateTime inicio;
  final List<String> motivos;
  final String otraParte;

  @override
  State<_DialogoCancelarServicio> createState() =>
      _DialogoCancelarServicioState();
}

class _DialogoCancelarServicioState extends State<_DialogoCancelarServicio> {
  String? _motivo;
  bool _faltaMotivo = false;

  void _confirmar() {
    if (_motivo == null) {
      setState(() => _faltaMotivo = true); // c2
      return;
    }
    Navigator.of(context).pop(_motivo);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tardia =
        ServicioService.esCancelacionTardia(widget.inicio, DateTime.now());

    return AlertDialog(
      title: const Text('¿Cancelar este servicio?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'El servicio del ${Formato.diaDeMes(widget.inicio)} quedará '
              'cancelado y ${widget.otraParte} verá el motivo que elijas.',
              style: textos.bodyMedium,
            ),
            if (tardia) ...[
              const SizedBox(height: 8),
              Text(
                'Faltan menos de 24 horas: quedará registrada como '
                'cancelación tardía.',
                style: textos.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            Text('Motivo', style: textos.titleSmall),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              key: const Key('motivo-cancelar-servicio'),
              initialValue: _motivo,
              hint: const Text('Selecciona un motivo'),
              items: [
                for (final motivo in widget.motivos)
                  DropdownMenuItem(value: motivo, child: Text(motivo)),
              ],
              onChanged: (valor) => setState(() {
                _motivo = valor;
                _faltaMotivo = false;
              }),
              decoration: InputDecoration(
                errorText:
                    _faltaMotivo ? ServicioService.mensajeEligeMotivo : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('cancelar-cancelacion'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('No'),
        ),
        FilledButton(
          key: const Key('confirmar-cancelacion'),
          style: AppTheme.botonPeligro,
          onPressed: _confirmar,
          child: const Text('Sí, cancelar'),
        ),
      ],
    );
  }
}
