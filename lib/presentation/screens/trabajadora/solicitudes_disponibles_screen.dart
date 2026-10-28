import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/postulacion.dart';
import '../../../domain/entities/solicitud_disponible.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/postulacion_service.dart';
import '../../providers/mis_postulaciones_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/dialogo_postular.dart';
import '../../widgets/estado_vacio.dart';
import 'banner_trabajadora.dart';
import 'barra_trabajadora.dart';
import 'panel_filtros_solicitudes.dart';
import 'tarjeta_solicitud.dart';

/// HU-11 · Ver solicitudes disponibles (Figma W06 · Trabajos disponibles).
///
/// Inicio de la trabajadora (ruta '/trabajadora'). Muestra las solicitudes
/// Publicadas, con fecha futura y de SUS zonas, y permite filtrarlas por
/// fecha y por tipo de limpieza.
///
/// Criterios de aceptación:
/// 1. Solo se ven solicitudes Publicadas de sus zonas con fecha futura
///    (lo garantiza el repositorio + la vista `solicitudes_publicas`).
/// 2. Al aplicar un filtro de fecha o de tipo, la lista muestra solo las
///    que lo cumplen (panel de filtros).
/// 3. Si no hay solicitudes en sus zonas, se muestra
///    "No hay solicitudes en tus zonas por ahora".
///
/// HU-12 · Cada tarjeta permite postularse (ver `TarjetaSolicitud`).
class SolicitudesDisponiblesScreen extends ConsumerWidget {
  const SolicitudesDisponiblesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';
    final fotoUrl = ref.watch(sesionProvider).value?.fotoUrl;
    final zonas = ref.watch(misZonasProvider).value ?? const <Zona>[];
    final movil = Responsive.esMovil(context);

    final filtros = PanelFiltrosSolicitudes(zonas: zonas);

    return Scaffold(
      body: Column(
        children: [
          BarraTrabajadora(nombre: nombre, fotoUrl: fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 16 : 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Encabezado(nombre: nombre),
                    SizedBox(height: movil ? 16 : 24),
                    filtros,
                    const SizedBox(height: 16),
                    const _ListaSolicitudes(),
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

/// Banner "Buenos días, Carmen" + resumen + insignia de identidad.
class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
    final saludo = Formato.saludo(DateTime.now());

    return BannerTrabajadora(
      saludo: primerNombre.isEmpty ? saludo : '$saludo, $primerNombre',
      resumen: _resumen(ref),
    );
  }

  /// "Hay 6 trabajos disponibles en tus zonas. Elige los que se ajusten
  /// mejor a tu horario."
  String _resumen(WidgetRef ref) {
    final zonas = ref.watch(misZonasProvider);
    final solicitudes = ref.watch(solicitudesDisponiblesProvider);

    if (zonas.isLoading || solicitudes.isLoading) {
      return 'Buscando trabajos en tus zonas…';
    }
    final misZonas = zonas.value ?? const <Zona>[];
    if (misZonas.isEmpty) {
      return 'Elige tus zonas de trabajo en tu perfil para ver solicitudes.';
    }

    final total = (solicitudes.value ?? const <SolicitudDisponible>[]).length;
    if (total == 0) {
      return 'Por ahora no hay trabajos en '
          '${Formato.lista([for (final zona in misZonas) zona.nombre])}.';
    }
    final trabajos = total == 1
        ? 'Hay 1 trabajo disponible'
        : 'Hay $total trabajos disponibles';
    return '$trabajos en tus zonas. '
        'Elige los que se ajusten mejor a tu horario.';
  }
}

/// Cuadrícula de tarjetas, o el estado que corresponda
/// (cargando, error, sin zonas, sin solicitudes, sin coincidencias).
class _ListaSolicitudes extends ConsumerWidget {
  const _ListaSolicitudes();

  /// HU-12 · Abre el diálogo de postulación y, si se envió, refresca la lista
  /// (el contador de postulantes sube y el botón queda en "Ya te postulaste")
  /// y confirma con un mensaje.
  Future<void> _postular(
    BuildContext context,
    WidgetRef ref,
    SolicitudDisponible solicitud,
  ) async {
    final enviada = await showDialog<bool>(
      context: context,
      builder: (context) => DialogoPostular(solicitud: solicitud),
    );
    if (enviada != true || !context.mounted) return;

    ref.invalidate(solicitudesDisponiblesProvider);
    ref.invalidate(misPostulacionesProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(PostulacionService.mensajeEnviada)),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonas = ref.watch(misZonasProvider);
    final todas = ref.watch(solicitudesDisponiblesProvider);
    final filtradas = ref.watch(solicitudesFiltradasProvider);
    final hayFiltros = ref.watch(filtroSolicitudesProvider).hayFiltros;

    // HU-12 c2 y c4: en qué tarjetas ya me postulé y si puedo postularme.
    final misPostulaciones =
        ref.watch(misPostulacionesProvider).value ?? const <Postulacion>[];
    final postuladas = {for (final p in misPostulaciones) p.solicitudId};
    final identidadVerificada = PostulacionService.identidadAprobada(
      ref.watch(sesionProvider).value?.verificacion,
    );

    if (zonas.isLoading || todas.isLoading) {
      return const _Caja(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final error = zonas.error ?? todas.error;
    if (error != null) {
      return _Caja(
        child: EstadoVacio(
          icono: Icons.wifi_off_rounded,
          titulo: error is AppException
              ? error.mensaje
              : 'No pudimos cargar las solicitudes.',
          textoBoton: 'Reintentar',
          onPressed: () {
            ref.invalidate(misZonasProvider);
            ref.invalidate(solicitudesDisponiblesProvider);
          },
        ),
      );
    }

    // Todavía no eligió zonas en su perfil (HU-04).
    if ((zonas.value ?? const <Zona>[]).isEmpty) {
      return const _Caja(
        child: EstadoVacio(
          icono: Icons.location_off_outlined,
          titulo: 'Aún no tienes zonas de trabajo',
          mensaje:
              'Cuando elijas tus zonas en el perfil, aquí verás las '
              'solicitudes publicadas en ellas.',
        ),
      );
    }

    // Criterio 3: no hay ninguna solicitud en sus zonas.
    if ((todas.value ?? const <SolicitudDisponible>[]).isEmpty) {
      return _Caja(
        child: EstadoVacio(
          icono: Icons.inbox_outlined,
          titulo: 'No hay solicitudes en tus zonas por ahora',
          mensaje: 'Vuelve más tarde: aparecerán apenas se publiquen.',
          textoBoton: 'Actualizar',
          onPressed: () => ref.invalidate(solicitudesDisponiblesProvider),
        ),
      );
    }

    final visibles = filtradas.value ?? const <SolicitudDisponible>[];

    // Hay solicitudes, pero ninguna cumple los filtros (criterio 2).
    if (visibles.isEmpty) {
      return _Caja(
        child: EstadoVacio(
          icono: Icons.filter_alt_off_outlined,
          titulo: 'Ninguna solicitud coincide con tus filtros',
          mensaje: hayFiltros ? 'Prueba con otra fecha, tipo o zona.' : null,
          textoBoton: 'Quitar filtros',
          onPressed: ref.read(filtroSolicitudesProvider.notifier).limpiar,
        ),
      );
    }

    return _Cuadricula(
      solicitudes: visibles,
      yaPostuladas: postuladas,
      identidadVerificada: identidadVerificada,
      onPostular: (solicitud) => _postular(context, ref, solicitud),
      // HU-45 · "Ver solicitud" abre el detalle completo.
      onVer: (solicitud) => context.go(Rutas.detalleSolicitud(solicitud.id)),
    );
  }
}

/// Reparte las tarjetas en 2 columnas (Figma W06), o 1 en pantallas angostas.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({
    required this.solicitudes,
    this.yaPostuladas = const <String>{},
    this.identidadVerificada = true,
    this.onPostular,
    this.onVer,
  });

  final List<SolicitudDisponible> solicitudes;
  final Set<String> yaPostuladas;
  final bool identidadVerificada;
  final void Function(SolicitudDisponible)? onPostular;
  final void Function(SolicitudDisponible)? onVer;

  static const _separacion = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final columnas = ancho >= 640 ? 2 : 1;
        final anchoTarjeta = (ancho - _separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: _separacion,
          runSpacing: _separacion,
          children: [
            for (final solicitud in solicitudes)
              SizedBox(
                width: anchoTarjeta,
                child: TarjetaSolicitud(
                  solicitud: solicitud,
                  yaPostulada: yaPostuladas.contains(solicitud.id),
                  identidadVerificada: identidadVerificada,
                  onPostular: onPostular == null
                      ? null
                      : () => onPostular!(solicitud),
                  onTap: onVer == null ? null : () => onVer!(solicitud),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Recuadro blanco para los mensajes (vacío, error, cargando).
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
