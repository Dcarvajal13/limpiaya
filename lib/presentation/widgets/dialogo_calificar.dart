import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/calificacion.dart';
import '../../domain/services/calificacion_service.dart';
import 'estrellas.dart';

/// Lo que eligió quien califica.
class CalificacionNueva {
  const CalificacionNueva({required this.estrellas, this.comentario});

  final int estrellas;
  final String? comentario;
}

/// HU-29 · Diálogo para calificar a [nombre] de 1 a 5 estrellas con un
/// comentario opcional. Devuelve lo elegido, o `null` si cancela.
/// c2: sin estrellas no deja enviar y muestra "Elige de 1 a 5 estrellas".
Future<CalificacionNueva?> mostrarDialogoCalificar(
  BuildContext context, {
  required String nombre,
}) {
  return showDialog<CalificacionNueva>(
    context: context,
    builder: (context) => _DialogoCalificar(nombre: nombre),
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
  const _DialogoCalificar({required this.nombre});

  final String nombre;

  @override
  State<_DialogoCalificar> createState() => _DialogoCalificarState();
}

class _DialogoCalificarState extends State<_DialogoCalificar> {
  final _comentario = TextEditingController();
  int? _estrellas;
  bool _faltanEstrellas = false;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!CalificacionService.estrellasValidas(_estrellas)) {
      setState(() => _faltanEstrellas = true); // c2
      return;
    }
    Navigator.of(context).pop(
      CalificacionNueva(
        estrellas: _estrellas!,
        comentario: CalificacionService.limpiarComentario(_comentario.text),
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
              Text(
                '¿Cómo te fue con el servicio? Tu opinión ayuda a otros '
                'clientes a elegir.',
                style: textos.bodyMedium,
              ),
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
              const SizedBox(height: 16),
              Text('Comentario (opcional)', style: textos.titleSmall),
              const SizedBox(height: 7),
              TextField(
                key: const Key('comentario-calificacion'),
                controller: _comentario,
                maxLines: 3,
                maxLength: CalificacionService.maxComentario,
                decoration: const InputDecoration(
                  hintText: 'Por ejemplo: muy puntual y cuidadosa.',
                ),
              ),
              Text(
                CalificacionService.mensajeOculta,
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
