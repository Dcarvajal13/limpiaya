import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/movimiento.dart';
import '../../../../core/utils/responsive.dart';
import 'comunes.dart';

/// Zonas de Caracas donde funciona LimpiaYa. Al tocar un municipio se ven
/// algunas de sus zonas.
///
/// Los nombres salen de la tabla `zonas` (migración del esquema inicial).
/// Si se agregan municipios allá, actualizar esta lista también.
class SeccionZonas extends StatefulWidget {
  const SeccionZonas({super.key});

  @override
  State<SeccionZonas> createState() => _SeccionZonasState();
}

class _SeccionZonasState extends State<SeccionZonas> {
  static const _zonasPorMunicipio = {
    'Baruta': ['Las Mercedes', 'Santa Fe', 'El Cafetal', 'Prados del Este', 'La Trinidad'],
    'Chacao': ['Altamira', 'Los Palos Grandes', 'La Castellana', 'El Rosal', 'Campo Alegre'],
    'El Hatillo': ['La Lagunita', 'Los Naranjos', 'La Boyera', 'Alto Hatillo'],
    'Sucre': ['Los Dos Caminos', 'La Urbina', 'Los Ruices', 'Sebucán', 'Macaracuay'],
    'Libertador': ['Sabana Grande', 'Los Chaguaramos', 'El Paraíso', 'San Bernardino', 'La Candelaria'],
  };

  String _municipio = 'Chacao';

  @override
  Widget build(BuildContext context) {
    final centrado = !Responsive.esMovil(context);

    return FranjaLanding(
      child: Column(
        crossAxisAlignment:
            centrado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          TituloSeccion(
            antetitulo: 'Caracas',
            titulo: 'Cerca de ti, de verdad.',
            texto: 'Comenzamos en cinco municipios y sus zonas más conocidas.',
            centrado: centrado,
          ),
          Wrap(
            alignment: centrado ? WrapAlignment.center : WrapAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final municipio in _zonasPorMunicipio.keys)
                ChoiceChip(
                  label: Text(municipio),
                  selected: municipio == _municipio,
                  onSelected: (_) => setState(() => _municipio = municipio),
                ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: Movimiento.animar(context) ? Movimiento.normal : Duration.zero,
            switchInCurve: Movimiento.salida,
            transitionBuilder: (child, animacion) => FadeTransition(
              opacity: animacion,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                    .animate(animacion),
                child: child,
              ),
            ),
            layoutBuilder: (actual, anteriores) => Stack(
              alignment: centrado ? Alignment.topCenter : Alignment.topLeft,
              children: [...anteriores, ?actual],
            ),
            child: Wrap(
              key: ValueKey(_municipio),
              alignment: centrado ? WrapAlignment.center : WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final zona in _zonasPorMunicipio[_municipio]!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.superficie,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borde),
                    ),
                    child: LineaConIcono(
                      icono: Icons.location_on_outlined,
                      texto: zona,
                      espacio: 6,
                      tamanoIcono: 17,
                      estilo: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.texto,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
