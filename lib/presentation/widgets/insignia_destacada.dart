import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/services/nivel_service.dart';

/// HU-61 · Insignia "Destacada" de una trabajadora.
///
/// Se ve en sus postulaciones (HU-14), en su perfil público (HU-06), en la
/// búsqueda (HU-25) y en "Mi reputación".
class InsigniaDestacada extends StatelessWidget {
  const InsigniaDestacada({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: NivelService.explicacion,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.insigniaAmbarFondo,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 15,
              color: AppColors.aviso,
            ),
            SizedBox(width: 5),
            Text(
              NivelService.nombreInsignia,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.aviso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
