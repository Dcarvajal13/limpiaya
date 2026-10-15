import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'comunes.dart';

/// Franja oscura: cómo LimpiaYa cuida la seguridad de ambos lados.
class SeccionConfianza extends StatelessWidget {
  const SeccionConfianza({super.key});

  static const _puntos = [
    (
      Icons.verified_user_outlined,
      'Identidad verificada',
      'Revisamos cédula y selfie antes de permitir postulaciones.',
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
    final columnas = ancho >= MedidasLanding.anchoDosColumnas
        ? 4
        : ancho >= 560
            ? 2
            : 1;

    return FranjaLanding(
      color: AppColors.primarioOscuro,
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
            children: [
              for (final (icono, titulo, texto) in _puntos)
                _TarjetaOscura(icono: icono, titulo: titulo, texto: texto),
            ],
          ),
        ],
      ),
    );
  }
}

class _TarjetaOscura extends StatelessWidget {
  const _TarjetaOscura({
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 28, color: AppColors.verdeSobreOscuro),
          const SizedBox(height: 28),
          Text(titulo, style: textos.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            texto,
            style: textos.bodySmall?.copyWith(color: AppColors.textoSuaveSobreOscuro),
          ),
        ],
      ),
    );
  }
}
