import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/aparecer.dart';
import '../../../widgets/logo_limpiaya.dart';
import '../../../widgets/pie_pagina.dart';
import '../../../widgets/resenas_rotativas.dart';

/// Diseño de las pantallas de inicio de sesión, registro y recuperación.
///
/// - Escritorio: panel azul pizarra a la izquierda con reseñas que se
///   turnan y, abajo, el título y el texto de la pantalla. A la derecha el
///   formulario en una tarjeta y el pie con Términos y Privacidad.
/// - Teléfono: el panel arriba (corto, sin reseñas, así el formulario
///   queda cerca) y el formulario debajo.
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

  /// Título grande del panel.
  final String titulo;

  /// Texto debajo del título del panel.
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
              child: _PanelAmplio(titulo: titulo, texto: texto),
            ),
            Expanded(
              flex: 11,
              child: LayoutBuilder(
                builder: (context, restricciones) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(48, 40, 48, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0.0, restricciones.maxHeight - 56),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 8),
                        Aparecer(
                          retraso: const Duration(milliseconds: 60),
                          child: _Formulario(compacto: false, child: child),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: _Pie(),
                        ),
                      ],
                    ),
                  ),
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
            _PanelCompacto(titulo: titulo, texto: texto),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: _Formulario(compacto: true, child: child),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _Pie(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie centrado debajo del formulario, del mismo ancho que la tarjeta.
class _Pie extends StatelessWidget {
  const _Pie();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 570),
        child: const PiePagina(compacto: true),
      ),
    );
  }
}

TextStyle? _estiloTitulo(BuildContext context, double tamano) =>
    Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: tamano,
          height: 1.1,
          color: Colors.white,
        );

TextStyle? _estiloTexto(BuildContext context, double tamano) =>
    Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: tamano,
          color: AppColors.textoSobreOscuro,
        );

/// Panel de escritorio: logo arriba, reseñas al centro y el título de la
/// pantalla abajo. Si la ventana es muy baja, se puede desplazar.
class _PanelAmplio extends StatelessWidget {
  const _PanelAmplio({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primarioOscuro,
      child: LayoutBuilder(
        builder: (context, restricciones) => SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0.0, restricciones.maxHeight - 96),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LogoLimpiaYa(
                  tamano: 40,
                  sobreOscuro: true,
                  onTap: () => context.go(Rutas.landing),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Aparecer(
                    child: ResenasRotativas(sobreOscuro: true, tamanoCita: 34),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 28),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // <h1> de las pantallas de inicio de sesión y registro.
                        Semantics(
                          container: true,
                          headingLevel: 1,
                          child: Text(titulo, style: _estiloTitulo(context, 30)),
                        ),
                        const SizedBox(height: 10),
                        Text(texto, style: _estiloTexto(context, 17)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel de teléfono: logo, título y texto, sin animaciones.
class _PanelCompacto extends StatelessWidget {
  const _PanelCompacto({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primarioOscuro,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogoLimpiaYa(
            tamano: 36,
            sobreOscuro: true,
            onTap: () => context.go(Rutas.landing),
          ),
          const SizedBox(height: 40),
          Semantics(
            container: true,
            headingLevel: 1,
            child: Text(titulo, style: _estiloTitulo(context, 32)),
          ),
          const SizedBox(height: 14),
          Text(texto, style: _estiloTexto(context, 16)),
        ],
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
