import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// Franja oscura: cómo LimpiaYa cuida la seguridad de ambos lados.
class SeccionConfianza extends StatelessWidget {
  const SeccionConfianza({super.key});

  static const _puntos = [
    (
      Icons.verified_user_outlined,
      'Identidad verificada',
      'Revisamos cédula y selfie de clientes y trabajadoras antes de '
          'publicar o postularse.',
    ),
    (
      Icons.star_outline_rounded,
      'Reseñas de ambos lados',
      'Clientes y trabajadoras construyen su reputación servicio a servicio.',
    ),
    (
      Icons.lock_outline_rounded,
      'Tu dirección es privada',
      'Solo la conoce la trabajadora que tú eliges.',
    ),
    (
      Icons.chat_bubble_outline_rounded,
      'Todo dentro de LimpiaYa',
      'Coordinen por el chat, sin mostrar teléfono ni correo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final movil = Responsive.esMovil(context);
    final columnas = ancho >= MedidasLanding.anchoDosColumnas
        ? 4
        : ancho >= 560
            ? 2
            : 1;

    // Banda redondeada dentro del ancho de la página, no de borde a borde.
    return FranjaLanding(
      vertical: movil ? 16 : 24,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: movil ? 24 : 56,
          vertical: movil ? 48 : 72,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarioOscuro,
          borderRadius: BorderRadius.circular(movil ? 24 : 32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloSeccion(
              antetitulo: 'Confianza primero',
              titulo: 'La seguridad está en cómo funciona, no en la letra pequeña.',
              sobreOscuro: true,
              anchoMaximo: 820,
            ),
            Rejilla(
              columnas: columnas,
              espacio: 28,
              children: [
                for (final (icono, titulo, texto) in _puntos)
                  _Punto(icono: icono, titulo: titulo, texto: texto),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.25))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 28, color: AppColors.verdeSobreOscuro),
          const SizedBox(height: 20),
          Text(
            titulo,
            style: textos.headlineSmall?.copyWith(fontSize: 23, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: textos.bodyMedium?.copyWith(color: AppColors.textoSuaveSobreOscuro),
          ),
        ],
      ),
    );
  }
}
