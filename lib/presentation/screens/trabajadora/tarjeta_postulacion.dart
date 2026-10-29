import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_postulacion.dart';
import '../../../domain/entities/postulacion.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta de una postulación en "Mis servicios" (HU-13, Figma W07 - Postulaciones).
///
/// Corrección de la revisión: el estado va arriba a la **derecha** y la
/// tarjeta muestra todo lo que la trabajadora necesita sin abrir nada:
/// - Fecha (cuadro con mes y día en escritorio), servicio y zona.
/// - Día, hora de inicio y horas estimadas; cliente; cuándo se postuló.
/// - Insignia del estado y "Recibes $X" a la derecha.
/// - Abajo, qué significa el estado y las acciones:
///   - Pendiente: "Ver solicitud" y "Retirar postulación" (HU-26, con
///     confirmación en la pantalla).
///   - Aceptada: "Ver servicio" (HU-13 c3, lleva al servicio agendado).
///   - No seleccionada / Cancelada / Retirada: solo el mensaje.
class TarjetaPostulacion extends StatelessWidget {
  const TarjetaPostulacion({
    super.key,
    required this.postulacion,
    this.onTap,
    this.onRetirar,
    this.onVerSolicitud,
  });

  final Postulacion postulacion;
  final VoidCallback? onTap;
  final VoidCallback? onRetirar;
  final VoidCallback? onVerSolicitud;

  TonoInsignia get _tono => switch (postulacion.estado) {
        EstadoPostulacion.pendiente => TonoInsignia.ambar,
        EstadoPostulacion.aceptada => TonoInsignia.verde,
        EstadoPostulacion.noSeleccionada => TonoInsignia.gris,
        EstadoPostulacion.retirada => TonoInsignia.gris,
        EstadoPostulacion.solicitudCancelada => TonoInsignia.rojo,
      };

  /// Qué significa el estado, en palabras de la trabajadora.
  String get _mensajeEstado => switch (postulacion.estado) {
        EstadoPostulacion.pendiente => 'Esperando que el cliente elija.',
        EstadoPostulacion.aceptada =>
          'El cliente te eligió. Revisa los detalles del servicio.',
        EstadoPostulacion.noSeleccionada =>
          'El cliente eligió a otra trabajadora.',
        EstadoPostulacion.retirada => 'Retiraste esta postulación.',
        EstadoPostulacion.solicitudCancelada =>
          'El cliente canceló esta solicitud.',
      };

  IconData get _iconoEstado => switch (postulacion.estado) {
        EstadoPostulacion.pendiente => Icons.hourglass_top_rounded,
        EstadoPostulacion.aceptada => Icons.check_circle_outline,
        _ => Icons.info_outline,
      };

  void _accionRetirar(BuildContext context) {
    if (onRetirar != null) return onRetirar!();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir la retirada de la postulación'),
        ),
      );
  }

  List<Widget> _acciones(BuildContext context) {
    switch (postulacion.estado) {
      case EstadoPostulacion.pendiente:
        return [
          OutlinedButton(
            key: Key('ver-solicitud-${postulacion.id}'),
            onPressed: onVerSolicitud,
            child: const Text('Ver solicitud'),
          ),
          TextButton(
            key: Key('retirar-${postulacion.id}'),
            onPressed: () => _accionRetirar(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primario,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Retirar postulación'),
          ),
        ];
      case EstadoPostulacion.aceptada:
        return [
          FilledButton(
            onPressed: onTap,
            child: const Text('Ver servicio'),
          ),
        ];
      case EstadoPostulacion.noSeleccionada:
      case EstadoPostulacion.retirada:
      case EstadoPostulacion.solicitudCancelada:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final p = postulacion;

    final insignia = InsigniaEstado(p.estado.etiqueta, tono: _tono);

    final pago = Text(
      'Recibes ${Formato.dinero(p.pagoOfrecido)}',
      style: textos.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primario,
      ),
    );

    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${p.tipo.servicio} · ${p.zona}',
          style: textos.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: movil ? 15 : 17,
            color: AppColors.texto,
          ),
        ),
        const SizedBox(height: 8),
        _Linea(
          icono: Icons.schedule,
          texto: '${Formato.diaDeSemana(p.inicio)}, ${Formato.hora(p.inicio)}'
              ' · ${Formato.horas(p.horasEstimadas)}',
        ),
        if (p.clienteNombre != null)
          _Linea(
            icono: Icons.person_outline,
            texto: 'Cliente: ${p.clienteNombre}',
          ),
        if (p.creadaEn != null)
          _Linea(
            icono: Icons.send_outlined,
            texto: 'Te postulaste el ${Formato.diaMesCorto(p.creadaEn!)}',
          ),
      ],
    );

    final acciones = _acciones(context);

    final pie = Row(
      children: [
        Icon(_iconoEstado, size: 18, color: AppColors.textoSecundario),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _mensajeEstado,
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
        ),
        if (!movil)
          for (final accion in acciones) ...[
            const SizedBox(width: 10),
            accion,
          ],
      ],
    );

    final contenido = movil
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      Formato.fechaLarga(p.inicio),
                      style: textos.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  insignia,
                ],
              ),
              const SizedBox(height: 8),
              datos,
              const SizedBox(height: 8),
              pago,
              const Divider(height: 24),
              pie,
              if (acciones.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: acciones,
                ),
              ],
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BloqueFecha(fecha: p.inicio),
                  const SizedBox(width: 18),
                  Expanded(child: datos),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      insignia,
                      const SizedBox(height: 12),
                      pago,
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),
              pie,
            ],
          );

    final esAceptada = p.estado == EstadoPostulacion.aceptada;

    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Al tocar una postulación aceptada también lleva al servicio
        // agendado (criterio 3).
        onTap: esAceptada ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: movil ? 16 : 24,
            vertical: movil ? 14 : 20,
          ),
          child: contenido,
        ),
      ),
    );
  }
}

/// Cuadro con el mes y el día, como en la tarjeta del cliente.
class _BloqueFecha extends StatelessWidget {
  const _BloqueFecha({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarioClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            Formato.mesMayus(fecha),
            style: textos.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primario,
            ),
          ),
          Text(
            '${fecha.day}',
            style: textos.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primarioOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea con ícono pequeño y texto secundario.
class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icono, size: 16, color: AppColors.textoSecundario),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
