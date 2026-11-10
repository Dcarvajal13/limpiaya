import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/acceso_perfil.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/logo_limpiaya.dart';

/// Barra superior del cliente: logo, pestañas y nombre de usuario.
class BarraCliente extends StatelessWidget {
  const BarraCliente({
    super.key,
    required this.nombre,
    this.fotoUrl,
    this.noLeidos = 0,
  });

  final String nombre;
  final String? fotoUrl;

  /// HU-38 · Mensajes sin leer, para el aviso de la pestaña "Mensajes".
  final int noLeidos;

  static const _altoPrincipal = 64.0;
  static const _altoPestanas = 48.0;

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final ubicacion = GoRouter.maybeOf(context)?.state.uri.toString() ?? '';

    final pestanas = _Pestanas(
      ubicacion: ubicacion,
      onMisSolicitudes: () => context.go(Rutas.inicioCliente),
      onPublicar: () => context.go(Rutas.publicarSolicitud),
      onBuscar: () => context.go(Rutas.buscarTrabajadoras),
      onMensajes: () => context.go(Rutas.mensajesCliente),
      noLeidos: noLeidos,
    );

    // Corrección del review: el avatar con el nombre abre el perfil, y
    // "Cerrar sesión" está dentro del perfil.
    final usuario = AccesoPerfil(
      nombre: nombre,
      fotoUrl: fotoUrl,
      rutaPerfil: Rutas.perfilCliente,
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
  const _Pestanas({
    required this.ubicacion,
    required this.onMisSolicitudes,
    required this.onPublicar,
    required this.onBuscar,
    required this.onMensajes,
    this.noLeidos = 0,
  });

  final String ubicacion;
  final VoidCallback onMisSolicitudes;
  final VoidCallback onPublicar;

  /// HU-25 · Buscar trabajadoras.
  final VoidCallback onBuscar;

  /// HU-38 · Lista de conversaciones.
  final VoidCallback onMensajes;
  final int noLeidos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pestana(
            etiqueta: 'Mis solicitudes',
            activa: ubicacion == Rutas.inicioCliente,
            onTap: onMisSolicitudes,
          ),
          _Pestana(
            etiqueta: 'Publicar',
            activa: ubicacion == Rutas.publicarSolicitud,
            onTap: onPublicar,
          ),
          _Pestana(
            etiqueta: 'Buscar trabajadoras',
            activa: ubicacion == Rutas.buscarTrabajadoras,
            onTap: onBuscar,
          ),
          _Pestana(
            etiqueta: 'Mensajes',
            activa: ubicacion == Rutas.mensajesCliente,
            onTap: onMensajes,
            contador: noLeidos,
          ),
        ],
      ),
    );
  }
}

class _Pestana extends StatelessWidget {
  const _Pestana({
    required this.etiqueta,
    this.activa = false,
    this.onTap,
    this.contador = 0,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback? onTap;

  /// Mensajes sin leer que se muestran como aviso.
  final int contador;

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  etiqueta,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                        color:
                            activa ? AppColors.primarioOscuro : AppColors.texto,
                      ),
                ),
                if (contador > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    key: const Key('aviso-mensajes'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primario,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$contador',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
