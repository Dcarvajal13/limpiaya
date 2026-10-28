import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/solicitud.dart';
import '../../providers/mis_solicitudes_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import 'banner_cliente.dart';
import 'barra_cliente.dart';
import 'tarjeta_solicitud_cliente.dart';

/// HU-08 · Ver mis solicitudes y su estado.
///
/// Pantalla principal del cliente (ruta '/cliente', Figma C05).
///
/// Criterios de aceptación:
/// 1. Las solicitudes se muestran ordenadas por fecha del servicio con su estado:
///    Publicada, Asignada, Completada o Cancelada.
/// 2. Cuando una solicitud tiene postulaciones, se muestra el número de postulantes.
/// 3. Si no tiene solicitudes, muestra un mensaje y un botón para publicar la primera.
/// 4. Filtros interactivos por estado: Todas, Publicadas, Asignadas, Completadas, Canceladas.
/// 5. Diseño responsivo con banner superior, métricas y tarjetas horizontales.
class MisSolicitudesScreen extends ConsumerStatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  ConsumerState<MisSolicitudesScreen> createState() =>
      _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends ConsumerState<MisSolicitudesScreen> {
  EstadoSolicitud? _filtroEstado;

  String _construirResumen(List<Solicitud> solicitudes) {
    final ahora = DateTime.now();
    final asignada = solicitudes
        .where((s) =>
            s.estado == EstadoSolicitud.asignada && s.inicio.isAfter(ahora))
        .toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    final proxima = asignada.firstOrNull;

    final conPostulantes = solicitudes
        .where((s) =>
            s.estado == EstadoSolicitud.publicada && s.numPostulantes > 0)
        .toList()
      ..sort((a, b) => b.numPostulantes.compareTo(a.numPostulantes));
    final esperando = conPostulantes.firstOrNull;

    final partes = <String>[];
    if (proxima != null) {
      final dia = Formato.diaDeSemana(proxima.inicio).toLowerCase();
      final hora = Formato.hora(proxima.inicio);
      partes.add(
        proxima.trabajadoraNombre != null
            ? '${proxima.trabajadoraNombre} va a tu casa el $dia a las $hora'
            : 'Tu servicio está agendado para el $dia a las $hora',
      );
    }
    if (esperando != null) {
      final prefijo = proxima != null ? 'Y tu solicitud' : 'Tu solicitud';
      partes.add(
        '$prefijo del ${Formato.diaDeSemana(esperando.inicio).toLowerCase()} '
        'ya tiene ${Formato.postulantes(esperando.numPostulantes)}.',
      );
    }

    if (partes.isEmpty) {
      return 'Revisa el estado de tus solicitudes o publica una nueva para recibir postulaciones.';
    }

    return partes.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion?.nombre ?? '';
    final fotoUrl = sesion?.fotoUrl;
    final movil = Responsive.esMovil(context);

    final solicitudesAsync = ref.watch(misSolicitudesProvider);
    // Calificación real del cliente; null si todavía no tiene reseñas.
    final calificacionPromedio = ref.watch(miPromedioProvider).value;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          BarraCliente(nombre: nombre, fotoUrl: fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 16 : 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner verde superior
                    BannerCliente(
                      saludo: nombre.isNotEmpty
                          ? 'Buenos días, $nombre'
                          : 'Buenos días',
                      resumen: solicitudesAsync.maybeWhen(
                        data: (solicitudes) => _construirResumen(solicitudes),
                        orElse: () =>
                            'Revisa el estado de tus solicitudes o publica una nueva.',
                      ),
                      onPublicar: () => context.go(Rutas.publicarSolicitud),
                    ),
                    const SizedBox(height: 20),

                    // Tarjetas de métricas superiores
                    solicitudesAsync.maybeWhen(
                      data: (solicitudes) => MetricasCliente(
                        solicitudes: solicitudes,
                        calificacionPromedio: calificacionPromedio,
                      ),
                      orElse: () => MetricasCliente(
                        solicitudes: const [],
                        calificacionPromedio: calificacionPromedio,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Título de la sección + Fila de filtros por estado
                    _BarraFiltros(
                      movil: movil,
                      filtroActual: _filtroEstado,
                      onFiltroSeleccionado: (estado) {
                        setState(() => _filtroEstado = estado);
                      },
                    ),
                    const SizedBox(height: 18),

                    // Lista de solicitudes
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

                        // Filtro local
                        final filtradas = _filtroEstado == null
                            ? solicitudes
                            : solicitudes
                                .where((s) => s.estado == _filtroEstado)
                                .toList();

                        if (filtradas.isEmpty) {
                          return _Caja(
                            child: EstadoVacio(
                              icono: Icons.filter_alt_off_outlined,
                              titulo:
                                  'No hay solicitudes ${_filtroEstado!.etiqueta.toLowerCase()}s',
                              mensaje:
                                  'Selecciona otro filtro para ver las demás solicitudes.',
                              textoBoton: 'Ver todas',
                              onPressed: () {
                                setState(() => _filtroEstado = null);
                              },
                            ),
                          );
                        }

                        // Criterios 1 y 2: solicitudes con estado y postulantes en tarjetas horizontales.
                        return Column(
                          children: [
                            for (final solicitud in filtradas) ...[
                              TarjetaSolicitudCliente(solicitud: solicitud),
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
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

/// Fila con el título "Mis solicitudes" y las píldoras de filtro.
class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.movil,
    required this.filtroActual,
    required this.onFiltroSeleccionado,
  });

  final bool movil;
  final EstadoSolicitud? filtroActual;
  final ValueChanged<EstadoSolicitud?> onFiltroSeleccionado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final titulo = Text(
      'Mis solicitudes',
      style: tema.textTheme.headlineMedium?.copyWith(
        fontSize: movil ? 20 : 24,
        fontWeight: FontWeight.w800,
        color: AppColors.primarioOscuro,
      ),
    );

    final listaFiltros = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PildoraFiltro(
            etiqueta: 'Todas',
            seleccionada: filtroActual == null,
            onTap: () => onFiltroSeleccionado(null),
          ),
          const SizedBox(width: 8),
          for (final estado in EstadoSolicitud.values) ...[
            _PildoraFiltro(
              etiqueta: '${estado.etiqueta}s',
              seleccionada: filtroActual == estado,
              onTap: () => onFiltroSeleccionado(estado),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,
          const SizedBox(height: 12),
          listaFiltros,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        titulo,
        const SizedBox(width: 16),
        Flexible(child: listaFiltros),
      ],
    );
  }
}

/// Píldora de filtro individual con estado activo/inactivo (Figma C05).
class _PildoraFiltro extends StatelessWidget {
  const _PildoraFiltro({
    required this.etiqueta,
    required this.seleccionada,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionada
              ? AppColors.primarioClaro.withValues(alpha: 0.5)
              : AppColors.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionada ? AppColors.primario : AppColors.borde,
            width: seleccionada ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seleccionada) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: AppColors.primarioOscuro,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              etiqueta,
              style: TextStyle(
                fontSize: 13,
                fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                color: seleccionada
                    ? AppColors.primarioOscuro
                    : AppColors.texto,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenedor con borde redondeado y fondo blanco para estados vacíos o de carga.
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
