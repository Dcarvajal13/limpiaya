import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/rutas.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/avatar_usuario.dart';
import '../../../widgets/estrellas.dart';
import '../../../widgets/insignia_verificada.dart';
import 'comunes.dart';

/// Bloque para trabajadoras: por qué les conviene y que es gratis para ellas.
class SeccionTrabajadoras extends StatelessWidget {
  const SeccionTrabajadoras({super.key});

  @override
  Widget build(BuildContext context) {
    final dosColumnas = MedidasLanding.dosColumnas(context);
    final movil = Responsive.esMovil(context);

    const imagen = _BloqueImagen();
    const texto = _TextoTrabajadoras();

    return FranjaLanding(
      color: AppColors.arena,
      vertical: movil ? 72 : 96,
      child: dosColumnas
          ? const Row(
              children: [
                Expanded(child: imagen),
                SizedBox(width: 80),
                Expanded(child: texto),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [imagen, SizedBox(height: 36), texto],
            ),
    );
  }
}

/// Foto de una trabajadora con una tarjeta de ejemplo encima.
///
/// La foto está en assets/images/trabajadora.jpg. Si no carga, se ve el
/// bloque arena de fondo y la tarjeta igual.
class _BloqueImagen extends StatelessWidget {
  const _BloqueImagen();

  static const _foto = 'assets/images/trabajadora.jpg';

  static const _forma = BorderRadius.only(
    topLeft: Radius.circular(32),
    topRight: Radius.circular(32),
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(120),
  );

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    return SizedBox(
      height: movil ? 350 : 480,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: _forma,
              child: Image.asset(
                _foto,
                fit: BoxFit.cover,
                semanticLabel: 'Una trabajadora limpiando una casa',
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.arenaOscura),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primarioOscuro.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const AvatarUsuario(nombre: 'Carmen Pérez'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Carmen Pérez', style: textos.titleMedium),
                          const SizedBox(height: 2),
                          const Estrellas(valor: 4.9, tamano: 16),
                          const SizedBox(height: 4),
                          const InsigniaVerificada(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextoTrabajadoras extends StatelessWidget {
  const _TextoTrabajadoras();

  static const _beneficios = [
    'Más clientes cerca de ti',
    'Tu reputación digital crece contigo',
    'Tú controlas zonas, servicios y tarifa',
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);
    final estiloBeneficio = textos.bodyMedium?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Antetitulo('Para trabajadoras'),
        const SizedBox(height: 12),
        Text(
          'Tu experiencia merece abrirte puertas.',
          style: textos.displayMedium?.copyWith(
            fontSize: movil ? 32 : 48,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        for (final beneficio in _beneficios) ...[
          LineaConIcono(
            icono: Icons.check_rounded,
            texto: beneficio,
            estilo: estiloBeneficio,
            espacio: 12,
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.superficie.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineaConIcono(
            icono: Icons.auto_awesome_rounded,
            texto: 'Usar LimpiaYa es gratis para las trabajadoras.',
            estilo: estiloBeneficio,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => context.go(Rutas.registroTrabajadora),
          child: const Text('Crear mi perfil'),
        ),
      ],
    );
  }
}
