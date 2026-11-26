import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/services/admin_service.dart';

/// Diálogo para reportar una reseña inapropiada (alimenta la cola de HU-35).
Future<void> mostrarDialogoReportarResena(
  BuildContext context,
  WidgetRef ref,
  String calificacionId,
) async {
  final motivo = await showDialog<String>(
    context: context,
    builder: (context) => const _DialogoReportar(),
  );
  if (motivo == null || !context.mounted) return;

  final mensajes = ScaffoldMessenger.of(context);
  try {
    await ref.read(adminServiceProvider).reportarResena(calificacionId, motivo);
    mensajes.showSnackBar(
      const SnackBar(
        content: Text('Reporte enviado. El equipo de moderación lo revisará.'),
      ),
    );
  } on AppException catch (e) {
    mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
  }
}

class _DialogoReportar extends StatefulWidget {
  const _DialogoReportar();

  @override
  State<_DialogoReportar> createState() => _DialogoReportarState();
}

class _DialogoReportarState extends State<_DialogoReportar> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _enviar() {
    final error = AdminService.validarMotivoReporte(_motivo.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_motivo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reportar reseña'),
      content: SizedBox(
        width: 400,
        child: TextFormField(
          controller: _motivo,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Motivo del reporte',
            hintText: 'Ej.: lenguaje ofensivo, información falsa…',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: AppTheme.botonPeligro,
          onPressed: _enviar,
          child: const Text('Enviar reporte'),
        ),
      ],
    );
  }
}
