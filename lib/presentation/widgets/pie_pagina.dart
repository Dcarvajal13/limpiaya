import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/rutas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import 'logo_limpiaya.dart';

/// Pie de página de toda la web: logo, enlaces (términos, privacidad,
/// sistema de diseño) y el crédito del proyecto.
///
/// Normalmente no se usa solo: [DesplazableConPie] lo pone al final de cada
/// pantalla y lo empuja al borde de abajo cuando el contenido es corto.
class PiePagina extends StatelessWidget {
  const PiePagina({super.key, this.onLogo});

  /// Qué hace el logo al tocarlo (en la landing, subir al inicio).
  final VoidCallback? onLogo;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final ancho = MediaQuery.sizeOf(context).width;
    final margen = Responsive.margen(context);
    final lateral =
        math.max(margen, (ancho - Responsive.anchoMaximo) / 2 + margen);
    final textos = Theme.of(context).textTheme;
    final pequeno =
        textos.bodySmall?.copyWith(color: AppColors.textoSecundario);

    final marca = Column(
      crossAxisAlignment:
          movil ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        LogoLimpiaYa(tamano: 34, onTap: onLogo),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Limpieza del hogar con trabajadoras verificadas en Caracas.',
            textAlign: movil ? TextAlign.center : TextAlign.start,
            style: pequeno,
          ),
        ),
      ],
    );

    final legal = _Columna(
      titulo: 'Legal',
      centrada: movil,
      enlaces: [
        _Enlace(
          'Términos y condiciones',
          key: const Key('pie-terminos'),
          onTap: () => context.push(Rutas.terminos),
        ),
        _Enlace(
          'Política de privacidad',
          key: const Key('pie-privacidad'),
          onTap: () => context.push(Rutas.privacidad),
        ),
      ],
    );

    final proyecto = _Columna(
      titulo: 'Proyecto',
      centrada: movil,
      enlaces: [
        _Enlace(
          'Sistema de diseño',
          onTap: () => context.push(Rutas.sistemaDiseno),
        ),
        const _Enlace('Ingeniería de Software · UNIMET'),
      ],
    );

    final credito = Text(
      '© 2026 LimpiaYa · Hecho en Caracas, Venezuela',
      textAlign: TextAlign.center,
      style: pequeno,
    );

    return Container(
      key: const Key('pie-pagina'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      padding: EdgeInsets.fromLTRB(lateral, movil ? 28 : 36, lateral, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (movil) ...[
            marca,
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 40,
              runSpacing: 16,
              children: [legal, proyecto],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: marca),
                const SizedBox(width: 24),
                Expanded(child: legal),
                const SizedBox(width: 24),
                Expanded(child: proyecto),
              ],
            ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          credito,
        ],
      ),
    );
  }
}

class _Columna extends StatelessWidget {
  const _Columna({
    required this.titulo,
    required this.enlaces,
    this.centrada = false,
  });

  final String titulo;
  final List<Widget> enlaces;
  final bool centrada;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centrada ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: textos.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.primario,
          ),
        ),
        const SizedBox(height: 8),
        ...enlaces,
      ],
    );
  }
}

/// Texto del pie que, si tiene [onTap], se comporta como enlace.
class _Enlace extends StatelessWidget {
  const _Enlace(this.texto, {super.key, this.onTap});

  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: onTap == null ? AppColors.textoSecundario : AppColors.texto,
        );
    final contenido = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(texto, style: estilo),
    );
    if (onTap == null) return contenido;
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: contenido,
      ),
    );
  }
}
