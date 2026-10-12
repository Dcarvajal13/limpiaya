import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../widgets/logo_limpiaya.dart';

/// Diseño de las pantallas de inicio de sesión y registro (Figma: Auth).
///
/// - Escritorio: panel verde oscuro a la izquierda y el formulario en una
///   tarjeta a la derecha.
/// - Teléfono: el panel verde arriba (más corto) y el formulario debajo.
///
/// Uso:
///   PlantillaAuth(
///     titulo: 'Qué bueno verte por aquí.',
///     texto: 'Tus solicitudes, mensajes y reseñas siguen esperándote.',
///     child: ...el formulario...,
///   )
class PlantillaAuth extends StatelessWidget {
  const PlantillaAuth({
    super.key,
    required this.titulo,
    required this.texto,
    required this.child,
  });

  /// Título grande del panel verde.
  final String titulo;

  /// Texto debajo del título del panel verde.
  final String texto;

  /// Lo que va dentro de la tarjeta blanca.
  final Widget child;

  static const _anchoDosColumnas = 900.0;

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MediaQuery.sizeOf(context).width >= _anchoDosColumnas;

    if (dosColumnas) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 9,
              child: _PanelVerde(titulo: titulo, texto: texto, compacto: false),
            ),
            Expanded(
              flex: 11,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                  child: _Formulario(compacto: false, child: child),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelVerde(titulo: titulo, texto: texto, compacto: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              child: _Formulario(compacto: true, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelVerde extends StatelessWidget {
  const _PanelVerde({
    required this.titulo,
    required this.texto,
    required this.compacto,
  });

  final String titulo;
  final String texto;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    final contenido = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LIMPIAYA',
          style: AppFonts.texto(
            const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
              color: AppColors.verdeSobreOscuro,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Text(
            titulo,
            style: textos.displayMedium?.copyWith(
              fontSize: compacto ? 32 : 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            texto,
            style: textos.bodyLarge?.copyWith(
              fontSize: compacto ? 16 : 18,
              color: AppColors.textoSobreOscuro,
            ),
          ),
        ),
      ],
    );

    final logo = LogoLimpiaYa(
      tamano: compacto ? 36 : 40,
      sobreOscuro: true,
      onTap: () => context.go(Rutas.landing),
    );

    if (compacto) {
      return Container(
        color: AppColors.primarioOscuro,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [logo, const SizedBox(height: 40), contenido],
        ),
      );
    }

    // En escritorio: logo arriba, texto al centro y crédito abajo.
    // Si la ventana es muy baja, el panel se puede desplazar.
    return ColoredBox(
      color: AppColors.primarioOscuro,
      child: LayoutBuilder(
        builder: (context, restricciones) => SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0.0, restricciones.maxHeight - 96),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  logo,
                  const SizedBox(height: 48),
                  contenido,
                  const SizedBox(height: 48),
                  Text(
                    'Proyecto de Ingeniería de Software · UNIMET',
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textoSobreOscuro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({required this.compacto, required this.child});

  final bool compacto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go(Rutas.landing),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Volver al inicio'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(compacto ? 24 : 40),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
