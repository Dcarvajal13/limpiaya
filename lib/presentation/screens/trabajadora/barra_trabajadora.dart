import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/acceso_perfil.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/logo_limpiaya.dart';

/// Barra superior de la trabajadora (Figma W06): logo, pestañas y su nombre.
///
/// Se coloca como primer elemento del cuerpo de la pantalla (no como
/// `appBar`) porque en móvil es más alta: las pestañas pasan a una segunda
/// fila para que todo quepa.
///
/// "Mis servicios" (HU-13) abre la pantalla con la pestaña Postulaciones.
class BarraTrabajadora extends StatelessWidget {
  const BarraTrabajadora({
    super.key,
    required this.nombre,
    this.fotoUrl,
  });

  final String nombre;

  /// Foto de perfil (HU-04), o null para mostrar las iniciales.
  final String? fotoUrl;

  static const _altoPrincipal = 64.0;
  static const _altoPestanas = 48.0;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    // maybeOf por si la barra se muestra fuera de un router (pruebas):
    // en ese caso ninguna pestaña queda activa.
    final ubicacion = GoRouter.maybeOf(context)?.state.uri.toString() ?? '';

    final pestanas = _Pestanas(
      ubicacion: ubicacion,
      onTrabajos: () => context.go(Rutas.inicioTrabajadora),
      onMisServicios: () => context.go(Rutas.misServicios),
    );

    // Corrección del review: "Mi perfil" y el nombre eran lo mismo. Ahora
    // el avatar con el nombre abre el perfil, y "Cerrar sesión" está dentro.
    final usuario = AccesoPerfil(
      nombre: nombre,
      fotoUrl: fotoUrl,
      rutaPerfil: Rutas.perfilTrabajadora,
    );

    return Material(
      color: AppColors.superficie,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borde)),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _altoPrincipal,
                child: ContenidoCentrado(
                  child: Row(
                    children: [
                      LogoLimpiaYa(tamano: 36, soloMarca: movil),
                      // Las pestañas usan el espacio que queda entre el
                      // logo y el nombre; si no caben, se desplazan en vez
                      // de desbordar la barra (ventanas de ~800 px).
                      if (!movil) ...[
                        const SizedBox(width: 16),
                        Expanded(child: Center(child: pestanas)),
                        const SizedBox(width: 16),
                      ] else
                        const Spacer(),
                      usuario,
                    ],
                  ),
                ),
              ),
              if (movil)
                SizedBox(
                  height: _altoPestanas,
                  child: ContenidoCentrado(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: pestanas,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({
    required this.ubicacion,
    required this.onTrabajos,
    required this.onMisServicios,
  });

  /// Dirección actual, para marcar la pestaña activa.
  final String ubicacion;
  final VoidCallback onTrabajos;
  final VoidCallback onMisServicios;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pestana(
          etiqueta: 'Trabajos',
          activa: ubicacion == Rutas.inicioTrabajadora,
          onTap: onTrabajos,
        ),
        _Pestana(
          etiqueta: 'Mis servicios',
          activa: ubicacion == Rutas.misServicios ||
              ubicacion.startsWith('${Rutas.misServicios}/'),
          onTap: onMisServicios,
        ),
      ],
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({required this.etiqueta, this.activa = false, this.onTap});

  final String etiqueta;
  final bool activa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: activa ? AppColors.primarioClaro : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              etiqueta,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 13,
                color: activa ? AppColors.primarioOscuro : AppColors.texto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
