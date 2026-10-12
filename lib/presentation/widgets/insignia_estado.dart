import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Colores de insignia del prototipo.
///
/// Uso sugerido:
/// - azul: Publicada, En revisión
/// - verde: Asignada, Aprobada, Aceptada
/// - gris: Completada, No seleccionada, Retirada
/// - rojo: Cancelada, Rechazada
/// - ambar: Pendiente, Por completar
enum TonoInsignia { azul, verde, gris, rojo, ambar }

/// Etiqueta pequeña y redondeada para mostrar un estado.
class InsigniaEstado extends StatelessWidget {
  const InsigniaEstado(this.texto, {super.key, required this.tono});

  final String texto;
  final TonoInsignia tono;

  @override
  Widget build(BuildContext context) {
    final (fondo, color) = switch (tono) {
      TonoInsignia.azul => (AppColors.insigniaAzulFondo, AppColors.insigniaAzulTexto),
      TonoInsignia.verde => (AppColors.insigniaVerdeFondo, AppColors.exito),
      TonoInsignia.gris => (AppColors.insigniaGrisFondo, AppColors.insigniaGrisTexto),
      TonoInsignia.rojo => (AppColors.insigniaRojaFondo, AppColors.error),
      TonoInsignia.ambar => (AppColors.insigniaAmbarFondo, AppColors.aviso),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
