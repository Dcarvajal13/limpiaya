import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/calificacion.dart';
import '../../domain/entities/motivo_calificacion_baja.dart';
import '../../domain/services/calificacion_service.dart';
import 'estrellas.dart';

/// Lo que eligió quien califica.
class CalificacionNueva {
  const CalificacionNueva({
    required this.estrellas,
    this.comentario,
    this.motivo,
  });

  final int estrellas;
  final String? comentario;

  /// HU-30 c2 · Solo con 1 o 2 estrellas y cuando el diálogo lo pide.
  final MotivoCalificacionBaja? motivo;
}

/// HU-29 / HU-30 · Diálogo para calificar a [nombre] de 1 a 5 estrellas con
/// un comentario opcional. Devuelve lo elegido, o `null` si cancela.
/// - HU-29 c2: sin estrellas no deja enviar ("Elige de 1 a 5 estrellas").
/// - HU-30 c2: con [pedirMotivo], 1 o 2 estrellas exigen un motivo.
Future<CalificacionNueva?> mostrarDialogoCalificar(
  BuildContext context, {
  required String nombre,
  String pregunta = '¿Cómo te fue con el servicio? Tu opinión ayuda a otros '
      'clientes a elegir.',
  String aviso = CalificacionService.mensajeOculta,
  String ejemplo = 'Por ejemplo: muy puntual y cuidadosa.',
  bool pedirMotivo = false,
}) {
  return showDialog<CalificacionNueva>(
    context: context,
    builder: (context) => _DialogoCalificar(
      nombre: nombre,
      pregunta: pregunta,
      aviso: aviso,
      ejemplo: ejemplo,
      pedirMotivo: pedirMotivo,
    ),
  );
}

/// HU-29 c3 · Muestra la calificación que ya dejó, sin poder enviar otra.
Future<void> mostrarMiCalificacion(
  BuildContext context, {
  required String nombre,
  required Calificacion calificacion,
}) {
  final textos = Theme.of(context).textTheme;
  final comentario = calificacion.comentario?.trim();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Tu calificación a $nombre'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Estrellas(
              valor: calificacion.estrellas.toDouble(),
              tamano: 30,
            ),
            const SizedBox(height: 12),
            Text(
              (comentario == null || comentario.isEmpty)
                  ? 'Sin comentario.'
                  : '“$comentario”',
              style: textos.bodyMedium,
            ),
            if (calificacion.fecha != null) ...[
              const SizedBox(height: 8),
              Text(
                'La enviaste el ${Formato.diaDeMes(calificacion.fecha!)}. '
                'Solo se puede calificar una vez por servicio.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          key: const Key('cerrar-mi-calificacion'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class _DialogoCalificar extends StatefulWidget {
  const _DialogoCalificar({
    required this.nombre,
    required this.pregunta,
    required this.aviso,
    required this.ejemplo,
    required this.pedirMotivo,
  });

  final String nombre;
  final String pregunta;
  final String aviso;
  final String ejemplo;
  final bool pedirMotivo;

  @override
  State<_DialogoCalificar> createState() => _DialogoCalificarState();
}

class _DialogoCalificarState extends State<_DialogoCalificar> {
  final _comentario = TextEditingController();
  int? _estrellas;
  bool _faltanEstrellas = false;
  MotivoCalificacionBaja? _motivo;
  bool _faltaMotivo = false;

  bool get _muestraMotivo =>
      widget.pedirMotivo && CalificacionService.requiereMotivo(_estrellas);

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!CalificacionService.estrellasValidas(_estrellas)) {
      setState(() => _faltanEstrellas = true); // HU-29 c2
      return;
    }
    if (widget.pedirMotivo &&
        CalificacionService.faltaMotivo(_estrellas, _motivo)) {
      setState(() => _faltaMotivo = true); // HU-30 c2
      return;
    }
    Navigator.of(context).pop(
      CalificacionNueva(
        estrellas: _estrellas!,
        comentario: CalificacionService.limpiarComentario(_comentario.text),
        motivo: _muestraMotivo ? _motivo : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('Califica a ${widget.nombre}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.pregunta, style: textos.bodyMedium),
              const SizedBox(height: 12),
              Center(
                child: Estrellas(
                  valor: (_estrellas ?? 0).toDouble(),
                  tamano: 30,
                  onChanged: (valor) => setState(() {
                    _estrellas = valor;
                    _faltanEstrellas = false;
                  }),
                ),
              ),
              if (_faltanEstrellas)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    CalificacionService.mensajeEligeEstrellas,
                    textAlign: TextAlign.center,
                    style: textos.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              // HU-30 c2: con 1 o 2 estrellas se pide el motivo.
              if (_muestraMotivo) ...[
                const SizedBox(height: 16),
                Text('¿Qué pasó?', style: textos.titleSmall),
                const SizedBox(height: 7),
                DropdownButtonFormField<MotivoCalificacionBaja>(
                  key: const Key('motivo-calificacion'),
                  initialValue: _motivo,
                  // "Condiciones distintas a lo publicado" es largo: en
                  // pantallas angostas se corta con "…" en vez de desbordar.
                  isExpanded: true,
                  hint: const Text('Selecciona un motivo'),
                  items: [
                    for (final motivo in MotivoCalificacionBaja.values)
                      DropdownMenuItem(
                        value: motivo,
                        child: Text(
                          motivo.etiqueta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (valor) => setState(() {
                    _motivo = valor;
                    _faltaMotivo = false;
                  }),
                  decoration: InputDecoration(
                    errorText: _faltaMotivo
                        ? CalificacionService.mensajeEligeMotivo
                        : null,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Comentario (opcional)', style: textos.titleSmall),
              const SizedBox(height: 7),
              TextField(
                key: const Key('comentario-calificacion'),
                controller: _comentario,
                maxLines: 3,
                maxLength: CalificacionService.maxComentario,
                decoration: InputDecoration(hintText: widget.ejemplo),
              ),
              Text(
                widget.aviso,
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('cancelar-calificacion'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          key: const Key('enviar-calificacion'),
          onPressed: _enviar,
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}
