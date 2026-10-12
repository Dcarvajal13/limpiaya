import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/contenido_centrado.dart';

/// Medidas propias de la landing.
///
/// Las secciones de dos columnas (hero, precio, trabajadoras…) se apilan
/// por debajo de 1000 px para que nada quede apretado en tablets.
abstract final class MedidasLanding {
  static const anchoDosColumnas = 1000.0;

  static bool dosColumnas(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= anchoDosColumnas;
}

/// Texto pequeño en mayúsculas que va arriba de un título ("ASÍ DE SENCILLO").
class Antetitulo extends StatelessWidget {
  const Antetitulo(this.texto, {super.key, this.sobreOscuro = false});

  final String texto;
  final bool sobreOscuro;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: AppFonts.texto(
        TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: sobreOscuro ? AppColors.verdeSobreOscuro : AppColors.primario,
        ),
      ),
    );
  }
}

/// Antetítulo + título + texto de apoyo, con el espacio de abajo incluido.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion({
    super.key,
    this.antetitulo,
    required this.titulo,
    this.texto,
    this.sobreOscuro = false,
    this.centrado = false,
    this.anchoMaximo = 700,
  });

  final String? antetitulo;
  final String titulo;
  final String? texto;
  final bool sobreOscuro;
  final bool centrado;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final alineacion = centrado ? TextAlign.center : TextAlign.start;

    return Padding(
      padding: EdgeInsets.only(bottom: movil ? 32 : 48),
      child: Align(
        alignment: centrado ? Alignment.center : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: anchoMaximo),
          child: Column(
            crossAxisAlignment:
                centrado ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              if (antetitulo != null) ...[
                Antetitulo(antetitulo!, sobreOscuro: sobreOscuro),
                const SizedBox(height: 12),
              ],
              Text(
                titulo,
                textAlign: alineacion,
                style: textos.headlineLarge?.copyWith(
                  fontSize: movil ? 28 : 36,
                  color: sobreOscuro ? Colors.white : null,
                ),
              ),
              if (texto != null) ...[
                const SizedBox(height: 16),
                Text(
                  texto!,
                  textAlign: alineacion,
                  style: textos.bodyLarge?.copyWith(
                    fontSize: movil ? 16 : 18,
                    color: sobreOscuro ? AppColors.textoSobreOscuro : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Franja de la landing: fondo de borde a borde y contenido centrado.
class FranjaLanding extends StatelessWidget {
  const FranjaLanding({
    super.key,
    required this.child,
    this.color,
    this.vertical,
    this.anchoMaximo = Responsive.anchoMaximo,
  });

  final Widget child;
  final Color? color;

  /// Espacio arriba y abajo. Si es null: 112 en escritorio y 72 en móvil.
  final double? vertical;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    final espacio = vertical ?? (Responsive.esMovil(context) ? 72.0 : 112.0);
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.symmetric(vertical: espacio),
      child: ContenidoCentrado(anchoMaximo: anchoMaximo, child: child),
    );
  }
}

/// Reparte [children] en filas de [columnas] elementos del mismo alto.
/// Con columnas = 1 queda una lista normal, una debajo de otra.
class Rejilla extends StatelessWidget {
  const Rejilla({
    super.key,
    required this.columnas,
    required this.children,
    this.espacio = 16,
  });

  final int columnas;
  final List<Widget> children;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var inicio = 0; inicio < children.length; inicio += columnas) {
      final celdas = <Widget>[];
      for (var j = 0; j < columnas; j++) {
        if (j > 0) celdas.add(SizedBox(width: espacio));
        final i = inicio + j;
        celdas.add(
          Expanded(
            // El alto de la fila se calcula antes de dibujar el texto. En la
            // web ese cálculo puede quedar una fracción de píxel corto y
            // Flutter avisa "overflowed". OverflowBox deja que la tarjeta
            // mida al menos el alto de la fila, sin ese aviso.
            child: OverflowBox(
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: i < children.length ? children[i] : const SizedBox(),
            ),
          ),
        );
      }
      if (filas.isNotEmpty) filas.add(SizedBox(height: espacio));
      filas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: celdas,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filas,
    );
  }
}

/// Ícono + texto en una línea (si no cabe, el texto baja a la siguiente).
class LineaConIcono extends StatelessWidget {
  const LineaConIcono({
    super.key,
    required this.icono,
    required this.texto,
    this.colorIcono = AppColors.primario,
    this.estilo,
    this.espacio = 10,
  });

  final IconData icono;
  final String texto;
  final Color colorIcono;
  final TextStyle? estilo;
  final double espacio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 22, color: colorIcono),
        SizedBox(width: espacio),
        Flexible(child: Text(texto, style: estilo)),
      ],
    );
  }
}
