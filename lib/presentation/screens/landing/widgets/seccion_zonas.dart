import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.arena,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _zonasPorMunicipio[_municipio]!.join(' · '),
              textAlign: centrado ? TextAlign.center : TextAlign.start,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
