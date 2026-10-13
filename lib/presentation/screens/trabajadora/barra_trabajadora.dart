import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/boton_cerrar_sesion.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/logo_limpiaya.dart';

/// Barra superior de la trabajadora (Figma W06): logo, pestañas y su nombre.
///
/// Se coloca como primer elemento del cuerpo de la pantalla (no como
/// `appBar`) porque en móvil es más alta: las pestañas pasan a una segunda
/// fila para que todo quepa.
///
/// TODO(HU-04 / HU-26): "Mis servicios" y "Mi perfil" todavía no tienen
/// pantalla; por ahora avisan que llegan pronto.
class BarraTrabajadora extends StatelessWidget {
  const BarraTrabajadora({super.key, required this.nombre});

  final String nombre;

  static const _altoPrincipal = 64.0;
  static const _altoPestanas = 48.0;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;

    final pestanas = _Pestanas(
      onProximamente: (nombre) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$nombre estará disponible pronto')),
        ),
    );

    final usuario = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarUsuario(nombre: nombre, tamano: 36),
        if (!movil) ...[
          const SizedBox(width: 10),
          Text(primerNombre, style: Theme.of(context).textTheme.labelMedium),
        ],
        const SizedBox(width: 8),
        const BotonCerrarSesion(),
      ],
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
                      if (!movil) ...[
                        const Spacer(),
                        pestanas,
                        const Spacer(),
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
                  child: ContenidoCentrado(child: pestanas),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.onProximamente});

  final void Function(String nombre) onProximamente;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Pestana(etiqueta: 'Trabajos', activa: true),
        _Pestana(
          etiqueta: 'Mis servicios',
          onTap: () => onProximamente('Mis servicios'),
        ),
        _Pestana(
          etiqueta: 'Mi perfil',
          onTap: () => onProximamente('Mi perfil'),
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
