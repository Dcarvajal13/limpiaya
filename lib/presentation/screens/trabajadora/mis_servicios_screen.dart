import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/postulacion.dart';
import '../../../domain/services/postulacion_service.dart';
import '../../providers/mis_postulaciones_provider.dart';
import '../../providers/retirar_postulacion_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import 'barra_trabajadora.dart';
import 'tarjeta_postulacion.dart';

enum _Pestana { proximos, postulaciones, pasados }

/// HU-13 · Ver mis postulaciones (Figma W07 · Mis servicios).
///
/// Pantalla de la trabajadora en '/trabajadora/servicios'. Tiene tres
/// pestañas; esta historia construye **Postulaciones**. "Próximos" y
/// "Pasados" son del seguimiento del servicio (HU-16) y por ahora muestran
/// que llegarán pronto.
///
/// Criterios de aceptación:
/// 1. Cada postulación se ve con su estado: Pendiente, Aceptada,
///    No seleccionada o Solicitud cancelada.
/// 2. Si el cliente eligió a otra trabajadora, la mía aparece como
///    No seleccionada (el estado se deduce en `EstadoPostulacion.resolver`).
/// 3. Al tocar una postulación Aceptada, lleva al detalle del servicio
///    agendado.
class MisServiciosScreen extends ConsumerStatefulWidget {
  const MisServiciosScreen({super.key});

  @override
  ConsumerState<MisServiciosScreen> createState() => _MisServiciosScreenState();
}

class _MisServiciosScreenState extends ConsumerState<MisServiciosScreen> {
  // Arranca en Postulaciones: es la única pestaña con contenido por ahora.
  _Pestana _pestana = _Pestana.postulaciones;

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final nombre = sesion?.nombre ?? '';
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final postulaciones = ref.watch(misPostulacionesProvider);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          BarraTrabajadora(nombre: nombre, fotoUrl: sesion?.fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 20 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mis servicios',
                      style: (movil ? textos.headlineLarge : textos.displaySmall)
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organiza tus próximos trabajos y postulaciones.',
                      style: textos.bodyLarge
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    _BarraPestanas(
                      actual: _pestana,
                      totalPostulaciones: postulaciones.value?.length,
                      onCambio: (p) => setState(() => _pestana = p),
                    ),
                    const SizedBox(height: 20),
                    switch (_pestana) {
                      _Pestana.postulaciones => const _ListaPostulaciones(),
                      _Pestana.proximos => const _Caja(
                          child: EstadoVacio(
                            icono: Icons.event_available_outlined,
                            titulo: 'Tus próximos servicios',
                            mensaje:
                                'Aquí verás los trabajos confirmados. '
                                'Estará disponible pronto.',
                          ),
                        ),
                      _Pestana.pasados => const _Caja(
                          child: EstadoVacio(
                            icono: Icons.history_rounded,
                            titulo: 'Tus servicios pasados',
                            mensaje:
                                'Aquí verás los trabajos ya realizados. '
                                'Estará disponible pronto.',
                          ),
                        ),
                    },
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

/// Lista de postulaciones, o el estado que corresponda
/// (cargando, error, sin postulaciones).
class _ListaPostulaciones extends ConsumerWidget {
  const _ListaPostulaciones();

  /// HU-26 · Pide confirmación y retira la postulación pendiente.
  ///
  /// Al terminar refresca las dos listas: la tarjeta sale de "Mis servicios"
  /// y, si la solicitud sigue Publicada, el trabajo vuelve a ofrecer
  /// "Postularme" en Trabajos (criterio 3).
  Future<void> _retirar(
    BuildContext context,
    WidgetRef ref,
    Postulacion postulacion,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar postulación'),
        content: const Text(
          'Tu postulación dejará de aparecer en la lista del cliente. '
          'Si el trabajo sigue publicado, puedes volver a postularte.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelar-retirar'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-retirar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final error = await ref
        .read(retirarPostulacionProvider.notifier)
        .retirar(postulacion.id);
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ref.invalidate(misPostulacionesProvider);
    ref.invalidate(solicitudesDisponiblesProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(PostulacionService.mensajeRetirada)),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postulaciones = ref.watch(misPostulacionesProvider);

    return postulaciones.when(
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
              : 'No pudimos cargar tus postulaciones.',
          textoBoton: 'Reintentar',
          onPressed: () => ref.invalidate(misPostulacionesProvider),
        ),
      ),
      data: (lista) {
        if (lista.isEmpty) {
          return _Caja(
            child: EstadoVacio(
              icono: Icons.assignment_outlined,
              titulo: 'Aún no te has postulado a ningún trabajo',
              mensaje: 'Busca solicitudes en tus zonas y postúlate '
                  'a las que se ajusten a tu horario.',
              textoBoton: 'Ver trabajos disponibles',
              onPressed: () => context.go(Rutas.inicioTrabajadora),
            ),
          );
        }
        return Column(
          children: [
            for (final Postulacion p in lista) ...[
              TarjetaPostulacion(
                postulacion: p,
                // Criterio 3: la aceptada lleva al servicio agendado.
                onTap: () =>
                    context.go(Rutas.servicioAgendado(p.solicitudId)),
                // HU-26: solo las pendientes ofrecen retirarse.
                onRetirar: () => _retirar(context, ref, p),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }
}

/// Pestañas "Próximos · Postulaciones (3) · Pasados" con línea inferior.
class _BarraPestanas extends StatelessWidget {
  const _BarraPestanas({
    required this.actual,
    required this.totalPostulaciones,
    required this.onCambio,
  });

  final _Pestana actual;
  final int? totalPostulaciones;
  final ValueChanged<_Pestana> onCambio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ItemPestana(
              etiqueta: 'Próximos',
              activa: actual == _Pestana.proximos,
              onTap: () => onCambio(_Pestana.proximos),
            ),
            _ItemPestana(
              etiqueta: 'Postulaciones',
              contador: totalPostulaciones,
              activa: actual == _Pestana.postulaciones,
              onTap: () => onCambio(_Pestana.postulaciones),
            ),
            _ItemPestana(
              etiqueta: 'Pasados',
              activa: actual == _Pestana.pasados,
              onTap: () => onCambio(_Pestana.pasados),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPestana extends StatelessWidget {
  const _ItemPestana({
    required this.etiqueta,
    required this.activa,
    required this.onTap,
    this.contador,
  });

  final String etiqueta;
  final bool activa;
  final VoidCallback onTap;
  final int? contador;

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.primario : AppColors.textoSecundario;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: activa ? AppColors.primario : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
            if (contador != null && contador! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarioClaro,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$contador',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primarioOscuro,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
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
