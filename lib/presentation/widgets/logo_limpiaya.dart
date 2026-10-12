import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Logo: casita en un cuadrado redondeado + "LimpiaYa".
///
/// [sobreOscuro] invierte los colores para fondos verdes oscuros.
class LogoLimpiaYa extends StatelessWidget {
  const LogoLimpiaYa({
    super.key,
    this.tamano = 40,
    this.sobreOscuro = false,
    this.subtitulo,
    this.onTap,
  });

  final double tamano;
  final bool sobreOscuro;

  /// Texto pequeño debajo del nombre, por ejemplo "Admin".
  final String? subtitulo;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorTexto = sobreOscuro ? Colors.white : AppColors.primarioOscuro;

    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            color: sobreOscuro ? Colors.white : AppColors.primario,
            borderRadius: BorderRadius.circular(tamano * 0.3),
          ),
          child: Icon(
            Icons.home_rounded,
            size: tamano * 0.55,
            color: sobreOscuro ? AppColors.primario : Colors.white,
          ),
        ),
        SizedBox(width: tamano * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LimpiaYa',
              style: AppFonts.titulos(
                TextStyle(
                  fontSize: tamano * 0.6,
                  fontWeight: FontWeight.w800,
                  color: colorTexto,
                  height: 1,
                ),
              ),
            ),
            if (subtitulo != null)
              Text(
                subtitulo!.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorTexto,
                ),
              ),
          ],
        ),
      ],
    );

    if (onTap == null) return logo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: logo,
    );
  }
}
