import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// "Identidad verificada" con escudo (HU-21, HU-06, HU-14).
class InsigniaVerificada extends StatelessWidget {
  const InsigniaVerificada({super.key, this.compacta = false});

  /// Si es true, muestra solo el escudo (para listas apretadas).
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    const icono = Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primario);
    if (compacta) {
      return const Tooltip(message: 'Identidad verificada', child: icono);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icono,
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Identidad verificada',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.primario, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
