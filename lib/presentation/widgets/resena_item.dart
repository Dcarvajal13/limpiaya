import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formato.dart';
import '../../domain/entities/perfil_publico.dart';
import 'estrellas.dart';

/// Una reseña: estrellas, quién la escribió, la fecha y el comentario.
///
/// La usan el perfil público de la trabajadora (HU-06), el perfil del cliente
/// que ve la trabajadora (HU-46) y "Mi reputación" (HU-31).
///
/// HU-31 c1 · Si quien la recibió respondió, la respuesta sale debajo.
class ResenaItem extends StatelessWidget {
  const ResenaItem({
    super.key,
    required this.resena,
    this.etiquetaRespuesta = 'Respuesta',
    this.pie,
  });

  final ResenaPublica resena;

  /// Título de la respuesta, por ejemplo "Respuesta de Carmen" o
  /// "Tu respuesta".
  final String etiquetaRespuesta;

  /// Acción debajo de la reseña (por ejemplo, el botón "Responder").
  final Widget? pie;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
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
                style: textos.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (resena.createdAt != null)
              Text(
                Formato.diaMesCorto(resena.createdAt!),
                style: textos.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.textoSecundario,
                ),
              ),
          ],
        ),
        if (resena.comentario != null) ...[
          const SizedBox(height: 6),
          Text(
            resena.comentario!,
            style: textos.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
        if (resena.tieneRespuesta) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.fondo,
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: AppColors.primario, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 16,
                      color: AppColors.primario,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        etiquetaRespuesta,
                        style: textos.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primario,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  resena.respuesta!.trim(),
                  style: textos.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
        if (pie != null) ...[
          const SizedBox(height: 8),
          pie!,
        ],
      ],
    );
  }
}
