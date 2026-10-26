import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/solicitud.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta de una solicitud del cliente (HU-08).
///
/// Muestra:
/// - Estado actual con su insignia (Publicada, Asignada, Completada, Cancelada)
/// - Número de postulantes (criterio 2)
/// - Tipo de limpieza y monto ofrecido
/// - Fecha, hora y duración estimada (criterio 1)
/// - Zona y características del inmueble (habitaciones, baños, mascotas)
/// - Método de pago y acción
class TarjetaSolicitudCliente extends StatelessWidget {
  const TarjetaSolicitudCliente({
    super.key,
    required this.solicitud,
    this.onTap,
  });

  final Solicitud solicitud;
  final VoidCallback? onTap;

  TonoInsignia _tono(EstadoSolicitud estado) => switch (estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  void _accion(BuildContext context) {
    if (onTap != null) return onTap!();
    final mensaje = switch (solicitud.estado) {
      EstadoSolicitud.publicada when solicitud.numPostulantes > 0 =>
        'La revisión de postulaciones estará disponible pronto (HU-13)',
      EstadoSolicitud.asignada =>
        'El seguimiento del servicio estará disponible pronto (HU-16)',
      _ => 'El detalle de la solicitud estará disponible pronto',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final detalle = textos.bodySmall?.copyWith(fontSize: 13);

    final tienePostulantes = solicitud.numPostulantes > 0;
    final textoPostulantes = tienePostulantes
        ? Formato.postulantes(solicitud.numPostulantes)
        : 'Sin postulantes aún';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                InsigniaEstado(
                  solicitud.estado.etiqueta,
                  tono: _tono(solicitud.estado),
                ),
                const Spacer(),
                Text(
                  textoPostulantes,
                  style: textos.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight:
                        tienePostulantes ? FontWeight.w600 : FontWeight.w400,
                    color: tienePostulantes
                        ? AppColors.primario
                        : AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    solicitud.tipo.etiqueta,
                    style: textos.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  Formato.dinero(solicitud.pagoOfrecido),
                  style: textos.titleLarge?.copyWith(
                    color: AppColors.primario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _Linea(
              icono: Icons.calendar_month_outlined,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Formato.diaTarjeta(solicitud.inicio),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.texto,
                      ),
                    ),
                    TextSpan(text: ' · ${Formato.hora(solicitud.inicio)}'),
                  ],
                ),
                style: detalle,
              ),
            ),
            _Linea(
              icono: Icons.schedule,
              child: Text(
                '${Formato.horas(solicitud.horasEstimadas)} estimadas',
                style: detalle,
              ),
            ),
            _Linea(
              icono: Icons.location_on_outlined,
              child: Text('${solicitud.zona}, Caracas', style: detalle),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Dato(
                  icono: Icons.bed_outlined,
                  texto: Formato.habitaciones(solicitud.habitaciones),
                ),
                _Dato(
                  icono: Icons.bathtub_outlined,
                  texto: Formato.banos(solicitud.banos),
                ),
                _Dato(
                  icono: Icons.pets_outlined,
                  texto:
                      solicitud.tieneMascotas ? 'Con mascotas' : 'Sin mascotas',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                const Icon(Icons.attach_money,
                    size: 18, color: AppColors.textoSecundario),
                const SizedBox(width: 4),
                Text(solicitud.metodoPago.etiqueta, style: detalle),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _accion(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: solicitud.estado == EstadoSolicitud.publicada &&
                        tienePostulantes
                    ? AppColors.primario
                    : AppColors.primarioOscuro,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_textoBoton()),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoBoton() {
    switch (solicitud.estado) {
      case EstadoSolicitud.publicada:
        return solicitud.numPostulantes > 0
            ? 'Ver postulaciones (${solicitud.numPostulantes})'
            : 'Ver solicitud';
      case EstadoSolicitud.asignada:
        return 'Ver servicio asignado';
      case EstadoSolicitud.completada:
        return 'Ver servicio completado';
      case EstadoSolicitud.cancelada:
        return 'Ver detalle';
    }
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.icono, required this.child});

  final IconData icono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.arena),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: AppColors.texto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.texto,
                ),
          ),
        ],
      ),
    );
  }
}
