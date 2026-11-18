import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/mi_verificacion.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/verificaciones_provider.dart';
import '../../widgets/insignia_verificada.dart';

/// HU-21 en Mi perfil: el estado de la verificación de identidad.
///
/// - c2: aprobada → insignia "Identidad verificada".
/// - c3: rechazada → el motivo y el botón para subir otra foto.
///
/// El estado sale de la sesión; el motivo solo se pide si fue rechazada.
///
/// También va en el perfil del cliente: ahí la verificación es para poder
/// publicar solicitudes.
class TarjetaVerificacionPerfil extends ConsumerWidget {
  const TarjetaVerificacionPerfil({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final estado = EstadoVerificacion.desdeTexto(sesion?.verificacion);
    final esCliente = sesion?.rol == RolUsuario.cliente;
    final para = esCliente ? 'publicar solicitudes' : 'postularte a solicitudes';
    final textos = Theme.of(context).textTheme;

    if (estado == EstadoVerificacion.aprobada) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: InsigniaVerificada(),
      );
    }

    final String titulo;
    String? detalle;
    String? textoBoton;
    var fondo = AppColors.primarioClaro;
    var color = AppColors.primario;
    var icono = Icons.shield_outlined;

    switch (estado) {
      case EstadoVerificacion.enRevision:
        titulo = 'Tu verificación está en revisión';
        detalle = esCliente
            ? 'Podrás publicar cuando sea aprobada.'
            : 'Podrás postularte cuando sea aprobada.';
        icono = Icons.hourglass_top_rounded;
      case EstadoVerificacion.rechazada:
        final motivo = ref.watch(miVerificacionProvider).value?.motivoRechazo;
        titulo = 'Tu verificación fue rechazada';
        detalle = motivo == null || motivo.trim().isEmpty
            ? null
            : 'Motivo: $motivo';
        textoBoton = 'Subir otra foto';
        fondo = AppColors.insigniaRojaFondo;
        color = AppColors.error;
        icono = Icons.gpp_bad_outlined;
      default:
        titulo = 'Aún no verificas tu identidad';
        detalle = 'La necesitas para $para.';
        textoBoton = 'Verificar mi identidad';
    }

    return Container(
      key: const Key('tarjeta-verificacion'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: textos.titleSmall?.copyWith(color: color)),
                if (detalle != null) Text(detalle, style: textos.bodySmall),
              ],
            ),
          ),
          if (textoBoton != null) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => context.go(Rutas.verificacionDe(sesion?.rol)),
              child: Text(textoBoton),
            ),
          ],
        ],
      ),
    );
  }
}
