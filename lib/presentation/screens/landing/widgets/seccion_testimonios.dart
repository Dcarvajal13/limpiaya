import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/avatar_usuario.dart';
import '../../../widgets/estrellas.dart';
import 'comunes.dart';

/// Dos testimonios de ejemplo (uno de cliente y uno de trabajadora).
/// Se aclara en pantalla que son de ejemplo.
class SeccionTestimonios extends StatelessWidget {
  const SeccionTestimonios({super.key});

  static const _testimonios = [
    (
      'Pude leer sobre Carmen antes de elegirla. Llegó puntual y todo quedó impecable.',
      'María Alejandra',
      'Cliente · Chacao',
    ),
    (
      'Ahora consigo trabajos cerca y cada reseña me ayuda a crecer por mi cuenta.',
      'Carmen Pérez',
      'Trabajadora · Baruta',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FranjaLanding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            antetitulo: 'Historias de la comunidad',
            titulo: 'Confianza que se construye de ambos lados.',
          ),
          Rejilla(
            columnas: MedidasLanding.dosColumnas(context) ? 2 : 1,
            espacio: 20,
            children: [
              for (final (cita, nombre, detalle) in _testimonios)
                _Testimonio(cita: cita, nombre: nombre, detalle: detalle),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Testimonios de ejemplo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Testimonio extends StatelessWidget {
  const _Testimonio({
    required this.cita,
    required this.nombre,
    required this.detalle,
  });

  final String cita;
  final String nombre;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Estrellas(valor: 5),
            const SizedBox(height: 24),
            Text(
              '“$cita”',
              style: AppFonts.titulos(
                TextStyle(
                  fontSize: movil ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: textos.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                AvatarUsuario(nombre: nombre),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: textos.titleMedium),
                      Text(detalle, style: textos.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
