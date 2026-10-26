import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/solicitud.dart';
import '../../providers/mis_solicitudes_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import 'barra_cliente.dart';
import 'tarjeta_solicitud_cliente.dart';

/// HU-08 · Ver mis solicitudes y su estado.
///
/// Pantalla principal del cliente (ruta '/cliente').
///
/// Criterios de aceptación:
/// 1. Las solicitudes se muestran ordenadas por fecha del servicio con su estado:
///    Publicada, Asignada, Completada o Cancelada.
/// 2. Cuando una solicitud tiene postulaciones, se muestra el número de postulantes.
/// 3. Si no tiene solicitudes, muestra un mensaje y un botón para publicar la primera.
class MisSolicitudesScreen extends ConsumerWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion?.nombre ?? '';
    final fotoUrl = sesion?.fotoUrl;
    final movil = Responsive.esMovil(context);

    final solicitudesAsync = ref.watch(misSolicitudesProvider);

    return Scaffold(
      body: Column(
        children: [
          BarraCliente(nombre: nombre, fotoUrl: fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 20 : 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Encabezado(
                      movil: movil,
                      onPublicar: () => context.go(Rutas.publicarSolicitud),
                    ),
                    const SizedBox(height: 24),
                    solicitudesAsync.when(
                      loading: () => const _Caja(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (error, _) => _Caja(
                        child: EstadoVacio(
                          icono: Icons.wifi_off_rounded,
                          titulo: error is AppException
                              ? error.mensaje
                              : 'No pudimos cargar tus solicitudes.',
                          textoBoton: 'Reintentar',
                          onPressed: () =>
                              ref.invalidate(misSolicitudesProvider),
                        ),
                      ),
                      data: (solicitudes) {
                        // Criterio 3: sin solicitudes se muestra mensaje y botón.
                        if (solicitudes.isEmpty) {
                          return _Caja(
                            child: EstadoVacio(
                              icono: Icons.inbox_outlined,
                              titulo: 'Aún no tienes solicitudes',
                              mensaje:
                                  'Publica una solicitud para recibir postulaciones '
                                  'de trabajadoras verificadas en tu zona.',
                              textoBoton: 'Publicar mi primera solicitud',
                              onPressed: () =>
                                  context.go(Rutas.publicarSolicitud),
                            ),
                          );
                        }

                        // Criterios 1 y 2: solicitudes con estado y postulantes.
                        return _Cuadricula(solicitudes: solicitudes);
                      },
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

/// Título y botón para crear una nueva solicitud.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.movil, required this.onPublicar});

  final bool movil;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final botonPublicar = FilledButton.icon(
      key: const Key('boton-publicar-solicitud'),
      onPressed: onPublicar,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Publicar solicitud'),
      style: FilledButton.styleFrom(
        minimumSize: Size(movil ? double.infinity : 0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mis solicitudes', style: tema.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Revisa el estado de tus solicitudes y las trabajadoras postuladas.',
            style: tema.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          botonPublicar,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis solicitudes', style: tema.textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Revisa el estado de tus solicitudes y las trabajadoras postuladas.',
                style: tema.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        botonPublicar,
      ],
    );
  }
}

/// Distribución de tarjetas en 2 columnas en pantallas medianas/grandes
/// o 1 columna en móvil.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.solicitudes});

  final List<Solicitud> solicitudes;

  static const _separacion = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final columnas = ancho >= 680 ? 2 : 1;
        final anchoTarjeta = (ancho - _separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: _separacion,
          runSpacing: _separacion,
          children: [
            for (final solicitud in solicitudes)
              SizedBox(
                width: anchoTarjeta,
                child: TarjetaSolicitudCliente(solicitud: solicitud),
              ),
          ],
        );
      },
    );
  }
}

/// Contenedor con borde redondeado y fondo blanco.
class _Caja extends StatelessWidget {
  const _Caja({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: child,
    );
  }
}
