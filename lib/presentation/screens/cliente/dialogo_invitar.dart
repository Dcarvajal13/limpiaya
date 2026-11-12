import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/perfil_publico.dart';
import '../../../domain/entities/solicitud.dart';
import '../../../domain/services/busqueda_service.dart';
import '../../providers/buscar_trabajadoras_provider.dart';

/// Lo que pasó al cerrar el diálogo de invitar.
enum ResultadoInvitar { invitada, irAPublicar }

/// HU-25 c3 · Elegir a cuál de mis solicitudes Publicadas invito a esta
/// trabajadora.
///
/// [publicadas]: todas mis solicitudes Publicadas y futuras.
/// [disponibles]: las que son en una zona donde ella trabaja y a las que
/// todavía no la invité (solo a esas se puede invitar).
/// [yaInvitadaEn]: a cuántas solicitudes de sus zonas ya la invité.
Future<ResultadoInvitar?> mostrarDialogoInvitar(
  BuildContext context, {
  required PerfilPublico trabajadora,
  required List<Solicitud> publicadas,
  required List<Solicitud> disponibles,
  int yaInvitadaEn = 0,
}) {
  return showDialog<ResultadoInvitar>(
    context: context,
    builder: (context) => DialogoInvitar(
      trabajadora: trabajadora,
      publicadas: publicadas,
      disponibles: disponibles,
      yaInvitadaEn: yaInvitadaEn,
    ),
  );
}

class DialogoInvitar extends ConsumerStatefulWidget {
  const DialogoInvitar({
    super.key,
    required this.trabajadora,
    required this.publicadas,
    required this.disponibles,
    this.yaInvitadaEn = 0,
  });

  final PerfilPublico trabajadora;
  final List<Solicitud> publicadas;
  final List<Solicitud> disponibles;
  final int yaInvitadaEn;

  @override
  ConsumerState<DialogoInvitar> createState() => _DialogoInvitarState();
}

class _DialogoInvitarState extends ConsumerState<DialogoInvitar> {
  late String? _elegida =
      widget.disponibles.length == 1 ? widget.disponibles.first.id : null;
  String? _error;
  bool _enviando = false;

  String get _nombre =>
      widget.trabajadora.nombre.trim().split(RegExp(r'\s+')).first;

  Future<void> _invitar() async {
    final solicitudId = _elegida;
    if (solicitudId == null) {
      setState(() => _error = 'Elige una solicitud');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    final error = await ref.read(invitarTrabajadoraProvider.notifier).invitar(
          solicitudId: solicitudId,
          trabajadoraId: widget.trabajadora.id,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _enviando = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(ResultadoInvitar.invitada);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    // Sin solicitudes Publicadas: primero hay que publicar una.
    if (widget.publicadas.isEmpty) {
      return AlertDialog(
        key: const Key('sin-publicaciones'),
        icon: const Icon(
          Icons.post_add_rounded,
          size: 32,
          color: AppColors.primario,
        ),
        title: const Text('Primero publica una solicitud'),
        content: SizedBox(
          width: 420,
          child: Text(
            'Para invitar a $_nombre necesitas una solicitud publicada: '
            'así sabrá qué día, a qué hora y en qué zona es el trabajo. '
            'Publícala y luego vuelve a invitarla.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            key: const Key('ir-a-publicar'),
            onPressed: () =>
                Navigator.of(context).pop(ResultadoInvitar.irAPublicar),
            child: const Text('Publicar solicitud'),
          ),
        ],
      );
    }

    // Ya la invitó a todas las que son en sus zonas.
    if (widget.disponibles.isEmpty && widget.yaInvitadaEn > 0) {
      return AlertDialog(
        key: const Key('ya-invitada'),
        title: Text('Ya invitaste a $_nombre'),
        content: SizedBox(
          width: 420,
          child: Text(
            widget.yaInvitadaEn == 1
                ? 'Ya la invitaste a tu solicitud en sus zonas. Verás su '
                    'postulación cuando se postule.'
                : 'Ya la invitaste a tus ${widget.yaInvitadaEn} solicitudes '
                    'en sus zonas. Verás su postulación cuando se postule.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    // Tiene Publicadas, pero ninguna en las zonas de ella.
    if (widget.disponibles.isEmpty) {
      return AlertDialog(
        title: Text('Invitar a $_nombre'),
        content: SizedBox(
          width: 420,
          child: Text(
            'Ninguna de tus solicitudes publicadas es en las zonas donde '
            'trabaja $_nombre, así que no podría postularse.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Invitar a $_nombre'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige la solicitud. $_nombre la verá marcada como '
                '«Te invitaron» y podrá postularse.',
                style: textos.bodyMedium,
              ),
              if (widget.yaInvitadaEn > 0) ...[
                const SizedBox(height: 6),
                Text(
                  widget.yaInvitadaEn == 1
                      ? 'Ya la invitaste a otra solicitud; aquí solo salen '
                          'las demás.'
                      : 'Ya la invitaste a ${widget.yaInvitadaEn} '
                          'solicitudes; aquí solo salen las demás.',
                  style: textos.bodySmall
                      ?.copyWith(color: AppColors.textoSecundario),
                ),
              ],
              const SizedBox(height: 12),
              for (final s in widget.disponibles)
                _OpcionSolicitud(
                  key: Key('invitar-a-${s.id}'),
                  solicitud: s,
                  elegida: _elegida == s.id,
                  onTap: _enviando
                      ? null
                      : () => setState(() {
                            _elegida = s.id;
                            _error = null;
                          }),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const Key('error-invitar'),
                  style: textos.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-invitar'),
          onPressed: _enviando ? null : _invitar,
          child: const Text('Enviar invitación'),
        ),
      ],
    );
  }
}

/// Una solicitud que se puede elegir (se marca con un check).
class _OpcionSolicitud extends StatelessWidget {
  const _OpcionSolicitud({
    super.key,
    required this.solicitud,
    required this.elegida,
    required this.onTap,
  });

  final Solicitud solicitud;
  final bool elegida;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: elegida ? AppColors.seleccionSuave : AppColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: elegida ? AppColors.primario : AppColors.borde,
            width: elegida ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  elegida
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: elegida ? AppColors.primario : AppColors.textoSecundario,
                  semanticLabel: elegida ? 'Elegida' : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${solicitud.tipo.etiqueta} · ${solicitud.zona}',
                        style: textos.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formato.diaCompletoHora(solicitud.inicio),
                        style: textos.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto de la confirmación (snackbar) después de invitar.
String mensajeInvitada(PerfilPublico trabajadora) =>
    BusquedaService.invitada(trabajadora.nombre);
