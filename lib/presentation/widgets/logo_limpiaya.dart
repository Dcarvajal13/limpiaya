import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Logo: casita en un cuadrado redondeado + "LimpiaYa".
///
/// [sobreOscuro] invierte los colores para fondos oscuros.
/// [soloMarca] muestra solo la casita (para pantallas muy angostas).
class LogoLimpiaYa extends StatelessWidget {
  const LogoLimpiaYa({
    super.key,
    this.tamano = 40,
    this.sobreOscuro = false,
    this.subtitulo,
    this.onTap,
    this.soloMarca = false,
  });

  final double tamano;
  final bool sobreOscuro;

  /// Texto pequeño debajo del nombre, por ejemplo "Admin".
  final String? subtitulo;

  final VoidCallback? onTap;
  final bool soloMarca;

  @override
  Widget build(BuildContext context) {
    final colorTexto = sobreOscuro ? Colors.white : AppColors.primarioOscuro;

    final marca = Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: sobreOscuro ? Colors.white : AppColors.primario,
        borderRadius: BorderRadius.circular(tamano * 0.27),
      ),
      child: Icon(
        Icons.home_rounded,
        size: tamano * 0.55,
        color: sobreOscuro ? AppColors.primario : Colors.white,
      ),
    );

    final Widget logo;
    if (soloMarca) {
      logo = Semantics(label: 'LimpiaYa', child: marca);
    } else {
      logo = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          marca,
          SizedBox(width: tamano * 0.25),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LimpiaYa',
                style: AppFonts.titulos(
                  TextStyle(
                    fontSize: tamano * 0.7,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: colorTexto,
                    height: 1,
                  ),
                ),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: AppFonts.texto(
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    if (onTap == null) return logo;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: logo,
    );
  }
}
