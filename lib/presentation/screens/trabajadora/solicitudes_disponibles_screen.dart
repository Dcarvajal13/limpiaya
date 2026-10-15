import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/solicitud_disponible.dart';
import '../../../domain/entities/zona.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
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
class SolicitudesDisponiblesScreen extends ConsumerWidget {
  const SolicitudesDisponiblesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';
    final fotoUrl = ref.watch(sesionProvider).value?.fotoUrl;
    final zonas = ref.watch(misZonasProvider).value ?? const <Zona>[];
    final movil = Responsive.esMovil(context);

    final filtros = PanelFiltrosSolicitudes(zonas: zonas);
    const lista = _ListaSolicitudes();

    return Scaffold(
      body: Column(
        children: [
          BarraTrabajadora(nombre: nombre, fotoUrl: fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 24 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Encabezado(nombre: nombre),
                    const SizedBox(height: 28),
                    if (movil) ...[
                      filtros,
                      const SizedBox(height: 16),
                      lista,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 250, child: filtros),
                          const SizedBox(width: 20),
                          const Expanded(child: lista),
                        ],
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

/// "Buenos días, Carmen" + resumen de la semana.
class _Encabezado extends ConsumerWidget {
  const _Encabezado({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final primerNombre = nombre.trim().split(RegExp(r'\s+')).first;
    final saludo = Formato.saludo(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primerNombre.isEmpty ? saludo : '$saludo, $primerNombre',
          style: textos.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(_resumen(ref), style: textos.bodyLarge?.copyWith(fontSize: 16)),
      ],
    );
  }

  /// "Hay 6 trabajos esta semana en Los Palos Grandes, Altamira y Chacao."
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

    final nombresZonas = Formato.lista([
      for (final zona in misZonas) zona.nombre,
    ]);
    final todas = solicitudes.value ?? const <SolicitudDisponible>[];
    final limite = DateTime.now().add(const Duration(days: 7));
    final estaSemana = todas.where((s) => s.inicio.isBefore(limite)).length;

    if (todas.isEmpty) return 'Por ahora no hay trabajos en $nombresZonas.';
    if (estaSemana == 0) {
      return 'Hay ${todas.length} '
          '${todas.length == 1 ? 'trabajo' : 'trabajos'} en $nombresZonas.';
    }
    return 'Hay $estaSemana ${estaSemana == 1 ? 'trabajo' : 'trabajos'} '
        'esta semana en $nombresZonas.';
  }
}

/// Cuadrícula de tarjetas, o el estado que corresponda
/// (cargando, error, sin zonas, sin solicitudes, sin coincidencias).
class _ListaSolicitudes extends ConsumerWidget {
  const _ListaSolicitudes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonas = ref.watch(misZonasProvider);
    final todas = ref.watch(solicitudesDisponiblesProvider);
    final filtradas = ref.watch(solicitudesFiltradasProvider);
    final hayFiltros = ref.watch(filtroSolicitudesProvider).hayFiltros;

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

    return _Cuadricula(solicitudes: visibles);
  }
}

/// Reparte las tarjetas en 3, 2 o 1 columnas según el ancho disponible.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.solicitudes});

  final List<SolicitudDisponible> solicitudes;

  static const _separacion = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth;
        final columnas = ancho >= 720 ? 3 : (ancho >= 480 ? 2 : 1);
        final anchoTarjeta = (ancho - _separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: _separacion,
          runSpacing: _separacion,
          children: [
            for (final solicitud in solicitudes)
              SizedBox(
                width: anchoTarjeta,
                child: TarjetaSolicitud(solicitud: solicitud),
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
