import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';

/// Banner verde del inicio de la trabajadora (Figma W06):
/// "Buenos días, Carmen", el resumen de trabajos y, a la derecha, la
/// insignia "Identidad verificada · ★ 4,9".
class BannerTrabajadora extends StatelessWidget {
  const BannerTrabajadora({
    super.key,
    required this.saludo,
    required this.resumen,
  });

  /// "Buenos días, Carmen".
  final String saludo;

  /// "Hay 6 trabajos disponibles en tus zonas. …".
  final String resumen;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    final titulo = Text(
      saludo,
      style: (movil ? textos.headlineMedium : textos.headlineLarge)
          ?.copyWith(color: Colors.white),
    );
    final subtitulo = Text(
      resumen,
      style: textos.bodyMedium?.copyWith(
        color: AppColors.verdeSobreOscuro,
        fontStyle: FontStyle.italic,
        fontSize: movil ? 14 : 15,
      ),
    );
    const insignia = InsigniaIdentidad();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: movil ? 22 : 32,
        vertical: movil ? 26 : 40,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Verde oscuro a la izquierda que se aclara hacia la derecha.
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primarioOscuro, AppColors.primario],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Brillo suave arriba a la derecha, como en el Figma.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.75, -0.6),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (movil)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titulo,
                const SizedBox(height: 8),
                subtitulo,
                const SizedBox(height: 16),
                insignia,
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titulo, const SizedBox(height: 10), subtitulo],
                  ),
                ),
                const SizedBox(width: 24),
                insignia,
              ],
            ),
        ],
      ),
    );
  }
}

/// Píldora con el estado de la verificación de identidad (HU-21) y el
/// promedio de estrellas, si ya tiene reseñas.
///
/// - aprobada    → "Identidad verificada · ★ 4,9"
/// - en_revision → "Verificación en revisión"
/// - rechazada   → "Verificación rechazada"
/// - pendiente   → "Identidad sin verificar"
class InsigniaIdentidad extends ConsumerWidget {
  const InsigniaIdentidad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificacion = ref.watch(sesionProvider).value?.verificacion;
    final promedio = ref.watch(miPromedioProvider).value;

    final (IconData icono, String texto) = switch (verificacion) {
      'aprobada' => (Icons.verified_user_outlined, 'Identidad verificada'),
      'en_revision' => (Icons.hourglass_top_rounded, 'Verificación en revisión'),
      'rechazada' => (Icons.gpp_bad_outlined, 'Verificación rechazada'),
      _ => (Icons.shield_outlined, 'Identidad sin verificar'),
    };

    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primarioOscuro,
          fontSize: 12,
        );

    return Container(
      key: const Key('insignia-identidad'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarioClaro,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: AppColors.primarioOscuro),
          const SizedBox(width: 6),
          Text(texto, style: estilo),
          if (promedio != null) ...[
            Text(' · ', style: estilo),
            const Icon(Icons.star_rounded, size: 15, color: AppColors.primarioOscuro),
            const SizedBox(width: 2),
            Text(Formato.promedio(promedio), style: estilo),
          ],
        ],
      ),
    );
  }
}
