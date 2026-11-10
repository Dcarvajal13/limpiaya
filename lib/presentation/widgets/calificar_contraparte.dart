import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/servicio_agendado.dart';
import '../../domain/services/calificacion_service.dart';
import '../providers/calificar_provider.dart';
import '../providers/mis_servicios_provider.dart';
import '../providers/mis_solicitudes_provider.dart';
import 'dialogo_calificar.dart';

/// HU-16 c4 · Califica a la otra parte de un servicio Completado.
///
/// Reutiliza el diálogo de HU-29 (cliente → trabajadora) y HU-30
/// (trabajadora → cliente): si ya califiqué, solo muestra lo que dejé; si no,
/// pide las estrellas y guarda la calificación.
Future<void> calificarContraparte(
  BuildContext context,
  WidgetRef ref,
  ServicioAgendado servicio,
) async {
  final mensajes = ScaffoldMessenger.of(context);
  final destinatarioId = servicio.contraparteId;
  if (destinatarioId == null) return;
  final nombre = servicio.contraparteNombre ?? 'la otra parte';

  try {
    final existente = await ref
        .read(calificacionRepositoryProvider)
        .miCalificacion(servicio.id);
    if (!context.mounted) return;
    if (existente != null) {
      await mostrarMiCalificacion(
        context,
        nombre: nombre,
        calificacion: existente,
      );
      return;
    }
  } on AppException catch (e) {
    mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    return;
  }

  final nueva = await mostrarDialogoCalificar(
    context,
    nombre: nombre,
    pregunta: servicio.soyCliente
        ? '¿Cómo te fue con el servicio? Tu opinión ayuda a otros clientes '
            'a elegir.'
        : '¿Cómo fue trabajar con este cliente? Tu opinión ayuda a otras '
            'trabajadoras.',
    aviso: servicio.soyCliente
        ? CalificacionService.mensajeOculta
        : CalificacionService.mensajeOcultaCliente,
    ejemplo: servicio.soyCliente
        ? 'Por ejemplo: muy puntual y cuidadosa.'
        : 'Por ejemplo: pagó a tiempo y fue muy amable.',
    pedirMotivo: !servicio.soyCliente,
  );
  if (nueva == null || !context.mounted) return;

  final error = await ref.read(calificarProvider.notifier).calificar(
        solicitudId: servicio.id,
        destinatarioId: destinatarioId,
        estrellas: nueva.estrellas,
        comentario: nueva.comentario,
        motivo: nueva.motivo,
      );
  if (!context.mounted) return;

  ref.invalidate(servicioAgendadoProvider(servicio.id));
  ref.invalidate(misServiciosProvider);
  ref.invalidate(misSolicitudesProvider);
  mensajes
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(error ?? CalificacionService.mensajeEnviada)),
    );
}
