import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// "Cómo funciona": los cinco pasos del servicio (HU-62, criterio 1).
class SeccionPasos extends StatelessWidget {
  const SeccionPasos({super.key});

  static const _pasos = [
    ('01', 'Publica', 'Cuéntanos cuándo, dónde y cuánto pagas. Tu dirección queda privada.'),
    ('02', 'Se postulan', 'Trabajadoras verificadas cercanas te cuentan por qué quieren ayudarte.'),
    ('03', 'Elige', 'Compara experiencia, reseñas e historia antes de decidir.'),
    ('04', 'Servicio', 'Coordinan por el chat de LimpiaYa, sin compartir teléfonos, y se hace la limpieza.'),
    ('05', 'Califican', 'Al terminar, ambas se califican y la comunidad se vuelve más confiable.'),
  ];

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MedidasLanding.dosColumnas(context);

    return FranjaLanding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            antetitulo: 'Así de sencillo',
            titulo: 'Tú publicas. Tú comparas. Tú eliges.',
            texto: 'Sin llamadas incómodas ni datos personales expuestos.',
          ),
          Rejilla(
            columnas: dosColumnas ? 5 : 1,
            espacio: 20,
            children: [
              for (final (numero, titulo, texto) in _pasos)
                _Paso(numero: numero, titulo: titulo, texto: texto),
            ],
          ),
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.titulo, required this.texto});

  final String numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    final estiloNumero = textos.labelLarge?.copyWith(
      color: AppColors.acento,
      fontWeight: FontWeight.w800,
    );
    final tituloTexto = Text(titulo, style: textos.titleLarge?.copyWith(fontSize: movil ? 18 : 20));
    final descripcion = Text(texto, style: textos.bodySmall);

    return Container(
      padding: const EdgeInsets.only(top: 22),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borde, width: 2)),
      ),
      child: MedidasLanding.dosColumnas(context)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(numero, style: estiloNumero),
                const SizedBox(height: 18),
                tituloTexto,
                const SizedBox(height: 8),
                descripcion,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 42, child: Text(numero, style: estiloNumero)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      tituloTexto,
                      const SizedBox(height: 6),
                      descripcion,
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
