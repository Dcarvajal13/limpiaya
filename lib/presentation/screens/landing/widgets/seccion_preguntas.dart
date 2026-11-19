import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// Preguntas frecuentes, que se abren y cierran. La primera empieza abierta.
class SeccionPreguntas extends StatelessWidget {
  const SeccionPreguntas({super.key});

  static const _preguntas = [
    (
      '¿Cómo sé que la trabajadora es quien dice ser?',
      'Cada trabajadora debe completar una verificación de identidad con su '
          'cédula y una selfie antes de poder postularse. Los clientes también '
          'se verifican antes de publicar.',
    ),
    (
      '¿En qué zonas está disponible?',
      'En zonas de Baruta, Chacao, El Hatillo, Sucre y Libertador.',
    ),
    (
      '¿Cómo se paga el servicio?',
      'Directamente a la trabajadora por Pago Móvil, transferencia o efectivo, '
          'en dólares o bolívares.',
    ),
    (
      '¿Qué pasa si una trabajadora no tiene reseñas?',
      'Verás la etiqueta “Nueva en la plataforma” y podrás valorar su '
          'experiencia y su presentación.',
    ),
    (
      '¿Necesito descargar una app?',
      'No. LimpiaYa funciona desde tu navegador, en computadora o teléfono.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FranjaLanding(
      anchoMaximo: 860 + 2 * Responsive.margen(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion(
            antetitulo: 'Preguntas frecuentes',
            titulo: 'Lo importante, sin vueltas.',
          ),
          for (final (i, (pregunta, respuesta)) in _preguntas.indexed)
            _Pregunta(
              pregunta: pregunta,
              respuesta: respuesta,
              abiertaAlInicio: i == 0,
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _Pregunta extends StatefulWidget {
  const _Pregunta({
    required this.pregunta,
    required this.respuesta,
    required this.abiertaAlInicio,
  });

  final String pregunta;
  final String respuesta;
  final bool abiertaAlInicio;

  @override
  State<_Pregunta> createState() => _PreguntaState();
}

class _PreguntaState extends State<_Pregunta> {
  late var _abierta = widget.abiertaAlInicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final duracion = Movimiento.animar(context) ? Movimiento.normal : Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Semantics(
          button: true,
          expanded: _abierta,
          child: InkWell(
            onTap: () => setState(() => _abierta = !_abierta),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.pregunta,
                        style: AppFonts.titulos(
                          TextStyle(
                            fontSize: movil ? 20 : 23,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: AppColors.texto,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // El "+" gira y queda como "×" cuando está abierta.
                    AnimatedRotation(
                      turns: _abierta ? 0.125 : 0,
                      duration: duracion,
                      curve: Movimiento.salida,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.arena,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_rounded, size: 20, color: AppColors.primario),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: duracion,
            curve: Movimiento.salida,
            alignment: Alignment.topCenter,
            child: _abierta
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 24, right: 56),
                    child: Text(
                      widget.respuesta,
                      style: textos.bodyMedium?.copyWith(
                        fontSize: 16.5,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}
