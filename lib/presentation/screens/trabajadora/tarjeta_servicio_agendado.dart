import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/servicio_agendado.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/insignia_estado.dart';

/// Tarjeta de un servicio en "Mis servicios" (HU-16).
///
/// Próximos (c1): fecha, hora, zona y la otra parte.
/// Pasados (c3): fecha, la otra parte, pago y estado; si está completado y
/// todavía no lo califiqué, ofrece "Calificar" (c4).
class TarjetaServicioAgendado extends StatelessWidget {
  const TarjetaServicioAgendado({
    super.key,
    required this.servicio,
    this.onTap,
    this.onCalificar,
  });

  final ServicioAgendado servicio;
  final VoidCallback? onTap;
  final VoidCallback? onCalificar;

  TonoInsignia get _tono => switch (servicio.estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  String get _cierre {
    final fecha = servicio.completadaEn ?? servicio.canceladaEn;
    if (fecha == null) return '';
    final verbo = servicio.estado == EstadoSolicitud.completada
        ? 'Completado'
        : 'Cancelado';
    return '$verbo el ${Formato.diaMesCorto(fecha)}';
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final s = servicio;

    final bloqueFecha = Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarioClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            Formato.mesMayus(s.inicio),
            style: textos.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primario,
            ),
          ),
          Text(
            '${s.inicio.day}',
            style: textos.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primarioOscuro,
            ),
          ),
        ],
      ),
    );

    final insignia = InsigniaEstado(s.estado.etiqueta, tono: _tono);

    final datos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.tipo.servicio} · ${s.zona}',
          style: textos.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: movil ? 15 : 17,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${Formato.fechaLarga(s.inicio)} · ${Formato.hora(s.inicio)}',
          style: textos.bodySmall?.copyWith(
            color: AppColors.textoSecundario,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            AvatarUsuario(
              nombre: s.contraparteNombre ?? '?',
              fotoUrl: s.contraparteFotoUrl,
              tamano: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.contraparteNombre ?? 'Sin nombre',
                style: textos.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (s.esPasado) ...[
          const SizedBox(height: 6),
          Text(
            [
              Formato.dinero(s.pagoOfrecido),
              if (_cierre.isNotEmpty) _cierre,
            ].join(' · '),
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ],
    );

    final calificar = s.puedeCalificar
        ? OutlinedButton(
            key: Key('calificar-${s.id}'),
            onPressed: onCalificar,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              side: const BorderSide(color: AppColors.primario, width: 1.5),
            ),
            child: const Text('Calificar'),
          )
        : null;

    return Material(
      color: AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: movil ? 16 : 22,
            vertical: movil ? 14 : 18,
          ),
          child: movil
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: insignia),
                        ?calificar,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bloqueFecha,
                        const SizedBox(width: 14),
                        Expanded(child: datos),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    bloqueFecha,
                    const SizedBox(width: 18),
                    Expanded(child: datos),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        insignia,
                        if (calificar != null) ...[
                          const SizedBox(height: 10),
                          calificar,
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
