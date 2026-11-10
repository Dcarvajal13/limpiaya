import 'package:flutter/material.dart';

import '../../../core/utils/formato.dart';
import '../../../domain/entities/solicitud.dart';

/// HU-17 · Confirmación antes de marcar el servicio como completado (H5 del
/// taller: diálogo antes de una acción que no se puede deshacer). Devuelve
/// `true` solo si el cliente confirma.
Future<bool> mostrarDialogoCompletar(
  BuildContext context,
  Solicitud solicitud,
) async {
  final nombre = solicitud.trabajadoraNombre;
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿La limpieza ya se hizo?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(
          'El servicio del ${Formato.diaDeMes(solicitud.inicio)}'
          '${nombre == null ? '' : ' con $nombre'} pasará a Completado. '
          'Después ya no se puede cancelar.',
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('cancelar-completar'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Todavía no'),
        ),
        FilledButton(
          key: const Key('confirmar-completar'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sí, se hizo'),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}

/// HU-17 c3 · Después de completar, invita a calificar a la trabajadora
/// (HU-29). Devuelve `true` si elige "Calificar ahora".
Future<bool> mostrarInvitacionCalificar(
  BuildContext context,
  Solicitud solicitud,
) async {
  final nombre = solicitud.trabajadoraNombre ?? 'a la trabajadora';
  final calificar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¡Servicio completado!'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(
          '¿Quieres calificar a $nombre? Tu opinión ayuda a otros clientes '
          'a elegir.',
        ),
      ),
      actions: [
        TextButton(
          key: const Key('calificar-despues'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Más tarde'),
        ),
        FilledButton(
          key: const Key('calificar-ahora'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Calificar ahora'),
        ),
      ],
    ),
  );
  return calificar ?? false;
}
