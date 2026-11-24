import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/contenido_centrado.dart';
import '../../../widgets/enlace_subrayado.dart';
import '../../../widgets/logo_limpiaya.dart';
import 'barra_visitante.dart';

/// Llamado final: banda redondeada con los dos caminos, cliente o
/// trabajadora.
class SeccionFinal extends StatelessWidget {
  const SeccionFinal({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;

    return ContenidoCentrado(
      vertical: movil ? 24 : 40,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: movil ? 24 : 64,
          vertical: movil ? 48 : 80,
        ),
        decoration: BoxDecoration(
          color: AppColors.primario,
          borderRadius: BorderRadius.circular(movil ? 24 : 32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Tu casa limpia, en manos que conoces.',
                style: textos.displayLarge?.copyWith(
                  fontSize: movil ? 38 : 64,
                  height: 1.04,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Comienza con una publicación. Decide solo cuando te sientas lista.',
              style: textos.bodyLarge?.copyWith(color: AppColors.textoSobreOscuro),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                FilledButton(
                  // Mismos colores de antes, con anillo de foco dorado.
                  style: AppTheme.botonAmbar,
                  onPressed: () => context.go(Rutas.registroCliente),
                  child: const Text('Necesito limpieza'),
                ),
                OutlinedButton(
                  style: AppTheme.botonContornoSobreOscuro,
                  onPressed: () => context.go(Rutas.registroTrabajadora),
                  child: const Text('Quiero trabajar'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Los términos, a la vista desde la página principal.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Al registrarte aceptas los ',
                  style: textos.bodySmall?.copyWith(color: AppColors.textoSobreOscuro),
                ),
                EnlaceSubrayado(
                  key: const Key('landing-terminos'),
                  texto: 'Términos y condiciones',
                  estilo: textos.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  colorHover: Colors.white,
                  onTap: () => context.push(Rutas.terminos),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pie de página completo de la landing: marca, correo de contacto, enlaces
/// por tipo de usuario y, abajo, el crédito con Términos y Privacidad.
///
/// Ojo: no repetir aquí los textos "Registrarme" ni "Iniciar sesión"; las
/// pruebas de la landing esperan encontrarlos una sola vez (en la barra).
class PieLanding extends StatelessWidget {
  const PieLanding({super.key, required this.onIrA, required this.onLogo});

  final ValueChanged<DestinoLanding> onIrA;
  final VoidCallback onLogo;

  static const _tenue = Color(0xFFA9BBD3);

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final estiloEnlace = AppFonts.texto(
      const TextStyle(fontSize: 15.5, color: Colors.white),
    );
    final estiloPequeno = AppFonts.texto(
      const TextStyle(fontSize: 14, color: AppColors.textoSobreOscuro),
    );

    Widget columna(String titulo, List<(String, VoidCallback)> enlaces) {
      return SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                titulo,
                style: AppFonts.texto(
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _tenue),
                ),
              ),
            ),
            const SizedBox(height: 4),
            for (final (texto, accion) in enlaces)
              EnlaceSubrayado(
                texto: texto,
                estilo: estiloEnlace,
                colorHover: Colors.white,
                onTap: accion,
              ),
          ],
        ),
      );
    }

    final marca = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogoLimpiaYa(tamano: 38, sobreOscuro: true, onTap: onLogo),
          const SizedBox(height: 16),
          Text(
            'Limpieza de confianza en Caracas. Trabajadoras verificadas, '
            'reseñas de ambos lados y precio claro desde el inicio.',
            style: AppFonts.texto(
              const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textoSobreOscuro),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline_rounded, size: 18, color: _tenue),
              const SizedBox(width: 8),
              // SelectionArea + Text: ver la nota en PiePagina.
              Flexible(
                child: SelectionArea(
                  child: Text(
                    AppConstants.correoSoporte,
                    style: AppFonts.texto(const TextStyle(fontSize: 15, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Landmark de pie de página (<footer>, rol contentinfo; WCAG 1.3.1).
    return Semantics(
      container: true,
      role: SemanticsRole.contentInfo,
      label: 'Pie de página',
      explicitChildNodes: true,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: movil ? 24 : 40),
        color: AppColors.primarioOscuro,
        child: ContenidoCentrado(
          child: Padding(
            padding: EdgeInsets.only(top: movil ? 48 : 72, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 56,
                  runSpacing: 40,
                  children: [
                    marca,
                    columna('LimpiaYa', [
                      for (final destino in DestinoLanding.values)
                        (destino.etiqueta, () => onIrA(destino)),
                    ]),
                    columna('Para clientes', [
                      ('Publicar una solicitud', () => context.go(Rutas.registroCliente)),
                      ('Entrar a mi cuenta', () => context.go(Rutas.login)),
                    ]),
                    columna('Para trabajadoras', [
                      ('Crear mi perfil', () => context.go(Rutas.registroTrabajadora)),
                      ('Verificar mi identidad', () => context.go(Rutas.verificacionTrabajadora)),
                    ]),
                  ],
                ),
                SizedBox(height: movil ? 40 : 56),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.18)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 32,
                  runSpacing: 4,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Proyecto de Ingeniería de Software, UNIMET, 2026',
                        style: estiloPequeno.copyWith(color: _tenue),
                      ),
                    ),
                    Wrap(
                      spacing: 24,
                      children: [
                        EnlaceSubrayado(
                          texto: 'Términos y condiciones',
                          estilo: estiloPequeno,
                          colorHover: Colors.white,
                          onTap: () => context.push(Rutas.terminos),
                        ),
                        EnlaceSubrayado(
                          texto: 'Política de privacidad',
                          estilo: estiloPequeno,
                          colorHover: Colors.white,
                          onTap: () => context.push(Rutas.privacidad),
                        ),
                        EnlaceSubrayado(
                          texto: 'Sistema de diseño',
                          estilo: estiloPequeno,
                          colorHover: Colors.white,
                          onTap: () => context.push(Rutas.sistemaDiseno),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
