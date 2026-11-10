import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../../domain/entities/servicio_agendado.dart';
import '../../../domain/services/servicio_service.dart';
import '../../providers/completar_servicio_provider.dart';
import '../../providers/mis_servicios_provider.dart';
import '../../providers/mis_solicitudes_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/calificar_contraparte.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';

/// HU-16 · Detalle de un servicio agendado, completado o cancelado.
///
/// Criterios:
/// 1. Se abre desde "Próximos"/"Pasados" de la trabajadora y desde el botón
///    "Ver servicio" del cliente.
/// 2. Muestra todos los datos: fecha, hora, zona, dirección y punto de
///    referencia, pago, método de pago, detalles de la vivienda, la otra
///    parte y el botón para escribirle por el chat (HU-38).
/// 3. Si está Completado y no lo califiqué, ofrece "Calificar" (HU-29).
class ServicioAgendadoScreen extends ConsumerWidget {
  const ServicioAgendadoScreen({super.key, required this.solicitudId});

  final String solicitudId;

  String _volverA(RolUsuario? rol) => rol == RolUsuario.cliente
      ? Rutas.inicioCliente
      : Rutas.misServicios;

  /// HU-17 · El cliente confirma que la limpieza se hizo.
  Future<void> _completar(
    BuildContext context,
    WidgetRef ref,
    ServicioAgendado servicio,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Marcar como completado?'),
        content: const Text(
          'Confirma que el servicio ya se realizó. Después podrás '
          'calificar a la otra parte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Todavía no'),
          ),
          FilledButton(
            key: const Key('confirmar-completar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Marcar como completado'),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final error = await ref
        .read(completarServicioProvider.notifier)
        .completar(servicio.id);
    if (!context.mounted) return;

    ref.invalidate(servicioAgendadoProvider(solicitudId));
    ref.invalidate(misServiciosProvider);
    ref.invalidate(misSolicitudesProvider);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? ServicioService.mensajeCompletado,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final detalle = ref.watch(servicioAgendadoProvider(solicitudId));
    final movil = Responsive.esMovil(context);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Servicio agendado'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(_volverA(sesion?.rol));
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          vertical: movil ? 20 : 40,
          anchoMaximo: 980,
          child: detalle.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => EstadoVacio(
              icono: Icons.wifi_off_rounded,
              titulo: error is AppException
                  ? error.mensaje
                  : 'No pudimos cargar el servicio.',
              textoBoton: 'Reintentar',
              onPressed: () =>
                  ref.invalidate(servicioAgendadoProvider(solicitudId)),
            ),
            data: (servicio) {
              if (servicio == null) {
                return EstadoVacio(
                  icono: Icons.search_off_rounded,
                  titulo: 'No encontramos este servicio',
                  mensaje: 'Es posible que ya no exista o que no sea tuyo.',
                  textoBoton: 'Volver',
                  onPressed: () => context.go(_volverA(sesion?.rol)),
                );
              }
              return _Contenido(
                servicio: servicio,
                movil: movil,
                onCompletar: () => _completar(context, ref, servicio),
                // HU-38: el chat solo existe cuando ya hay trabajadora
                // asignada (mientras está Publicada no hay con quién hablar).
                onChat: servicio.estado == EstadoSolicitud.publicada
                    ? null
                    : () =>
                        context.push(Rutas.chatServicio(servicio.id)),
                onCalificar: () => calificarContraparte(context, ref, servicio),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.servicio,
    required this.movil,
    required this.onCompletar,
    required this.onChat,
    required this.onCalificar,
  });

  final ServicioAgendado servicio;
  final bool movil;
  final VoidCallback onCompletar;

  /// HU-38 · Null cuando todavía no hay con quién chatear.
  final VoidCallback? onChat;
  final VoidCallback onCalificar;

  TonoInsignia get _tono => switch (servicio.estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  String get _productos {
    final quien = servicio.productosPor;
    if (quien == null) return 'Sin especificar';
    return servicio.soyCliente ? quien.etiqueta : 'Los pone el cliente';
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    final cabecera = Container(
      width: double.infinity,
      padding: EdgeInsets.all(movil ? 20 : 28),
      decoration: BoxDecoration(
        color: AppColors.primarioOscuro,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InsigniaEstado(servicio.estado.etiqueta, tono: _tono),
          const SizedBox(height: 14),
          Text(
            servicio.tipo.servicio,
            style: textos.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formato.fechaLarga(servicio.inicio)} · '
            '${Formato.hora(servicio.inicio)}',
            style: textos.bodyLarge?.copyWith(
              color: AppColors.textoSobreOscuro,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${servicio.zona} · ${Formato.horas(servicio.horasEstimadas)}',
            style: textos.bodyMedium?.copyWith(
              color: AppColors.verdeSobreOscuro,
            ),
          ),
          if (servicio.estado == EstadoSolicitud.asignada) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: AppColors.textoSobreOscuro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Termina alrededor de las '
                    '${Formato.horaFin(servicio.inicio, servicio.horasEstimadas)}',
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textoSobreOscuro,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    final pago = _Caja(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              servicio.soyCliente ? 'Pago ofrecido' : 'Recibes',
              style: textos.labelLarge?.copyWith(
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formato.dinero(servicio.pagoOfrecido),
              style: textos.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primario,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              servicio.metodoPago.etiqueta,
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
    );

    final datos = _Caja(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dónde y cuándo',
              style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _Dato(
              icono: Icons.event_outlined,
              titulo: Formato.fechaLarga(servicio.inicio),
              detalle:
                  '${Formato.hora(servicio.inicio)} · '
                  '${Formato.horas(servicio.horasEstimadas)}',
            ),
            _Dato(
              icono: Icons.location_on_outlined,
              titulo: servicio.direccion ?? 'Dirección no disponible',
              detalle: [
                servicio.zona,
                if (servicio.puntoReferencia != null &&
                    servicio.puntoReferencia!.trim().isNotEmpty)
                  'Ref.: ${servicio.puntoReferencia}',
              ].join(' · '),
            ),
            const Divider(height: 28),
            Text(
              'Detalles de la vivienda',
              style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Chip(
                  icono: Icons.bed_outlined,
                  texto: Formato.habitaciones(servicio.habitaciones),
                ),
                _Chip(
                  icono: Icons.bathtub_outlined,
                  texto: Formato.banos(servicio.banos),
                ),
                _Chip(
                  icono: Icons.pets_outlined,
                  texto: servicio.tieneMascotas ? 'Con mascotas' : 'Sin mascotas',
                ),
                _Chip(
                  icono: Icons.cleaning_services_outlined,
                  texto: 'Productos: $_productos',
                ),
              ],
            ),
            if ((servicio.notas ?? '').trim().isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Notas del cliente',
                style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(servicio.notas!, style: textos.bodyMedium),
            ],
            if (servicio.estado == EstadoSolicitud.cancelada &&
                (servicio.motivoCancelacion ?? '').trim().isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                'Motivo de la cancelación',
                style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(servicio.motivoCancelacion!, style: textos.bodyMedium),
            ],
          ],
        ),
      ),
    );

    final otraParte = _Caja(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              servicio.soyCliente ? 'Tu trabajadora' : 'Cliente',
              style: textos.labelLarge?.copyWith(
                color: AppColors.textoSecundario,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AvatarUsuario(
                  nombre: servicio.contraparteNombre ?? '?',
                  fotoUrl: servicio.contraparteFotoUrl,
                  tamano: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio.contraparteNombre ?? 'Sin nombre',
                        style: textos.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        servicio.contrapartePromedio != null
                            ? '★ ${Formato.promedio(servicio.contrapartePromedio!)}'
                            : 'Sin calificaciones aún',
                        style: textos.bodySmall?.copyWith(
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onChat != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('chat-servicio'),
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Escribir por el chat'),
              ),
            ],
          ],
        ),
      ),
    );

    final acciones = <Widget>[
      if (servicio.puedeCompletar)
        FilledButton.icon(
          key: const Key('completar-servicio'),
          onPressed: onCompletar,
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Marcar como completado'),
        ),
      if (servicio.puedeCalificar)
        FilledButton.icon(
          key: const Key('calificar-servicio'),
          onPressed: onCalificar,
          icon: const Icon(Icons.star_outline, size: 18),
          label: const Text('Calificar'),
        ),
    ];

    final columnaPrincipal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cabecera,
        const SizedBox(height: 16),
        datos,
      ],
    );

    final columnaLateral = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pago,
        const SizedBox(height: 16),
        otraParte,
        if (acciones.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final accion in acciones) ...[
            accion,
            const SizedBox(height: 10),
          ],
        ],
      ],
    );

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cabecera,
          const SizedBox(height: 16),
          pago,
          const SizedBox(height: 16),
          datos,
          const SizedBox(height: 16),
          otraParte,
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final accion in acciones) ...[
              accion,
              const SizedBox(height: 10),
            ],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: columnaPrincipal),
        const SizedBox(width: 20),
        SizedBox(width: 320, child: columnaLateral),
      ],
    );
  }
}

/// Línea con ícono, título y detalle.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarioClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: AppColors.primario),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: textos.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detalle.isNotEmpty)
                  Text(
                    detalle,
                    style: textos.bodySmall?.copyWith(
                      color: AppColors.textoSecundario,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: AppColors.textoSecundario),
          const SizedBox(width: 6),
          Text(texto, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

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
