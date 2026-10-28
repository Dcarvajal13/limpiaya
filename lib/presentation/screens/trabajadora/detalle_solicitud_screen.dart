import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/postulacion.dart';
import '../../../domain/entities/quien_pone_productos.dart';
import '../../../domain/entities/solicitud_disponible.dart';
import '../../../domain/services/postulacion_service.dart';
import '../../providers/mis_postulaciones_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/solicitudes_disponibles_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/dialogo_postular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';

/// HU-45 · Ver el detalle de una solicitud antes de postularse.
///
/// Criterios:
/// 1. Muestra fecha, hora, horas estimadas, tipo de limpieza, zona, pago,
///    método de pago y número de postulantes.
/// 2. Nunca aparece la dirección exacta del cliente: la vista pública ni
///    siquiera la trae, y aquí se avisa cuándo la verá.
/// 3. Si la solicitud dejó de estar Publicada mientras la miraba, al presionar
///    "Postularme" ve "Esta solicitud ya no está disponible" (lo comprueba el
///    repositorio al insertar).
class DetalleSolicitudScreen extends ConsumerWidget {
  const DetalleSolicitudScreen({super.key, required this.solicitudId});

  final String solicitudId;

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

    ref.invalidate(solicitudDetalleProvider(solicitudId));
    ref.invalidate(solicitudesDisponiblesProvider);
    ref.invalidate(misPostulacionesProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(PostulacionService.mensajeEnviada)),
      );
  }

  /// HU-12 c4 · Sin identidad aprobada no se postula: se avisa y se ofrece ir.
  Future<void> _avisarSinVerificar(BuildContext context) async {
    final quiereVerificar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Antes de postularte'),
        content: const Text(PostulacionService.mensajeVerificacion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            key: const Key('ir-a-verificacion'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verificar mi identidad'),
          ),
        ],
      ),
    );
    if (quiereVerificar == true && context.mounted) {
      context.go(Rutas.verificacionTrabajadora);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalle = ref.watch(solicitudDetalleProvider(solicitudId));
    final movil = Responsive.esMovil(context);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: const Text('Detalle de la solicitud'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver a los trabajos',
          onPressed: () => context.go(Rutas.inicioTrabajadora),
        ),
      ),
      body: SingleChildScrollView(
        child: ContenidoCentrado(
          vertical: movil ? 20 : 40,
          anchoMaximo: 760,
          child: detalle.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => EstadoVacio(
              icono: Icons.wifi_off_rounded,
              titulo: error is AppException
                  ? error.mensaje
                  : 'No pudimos cargar la solicitud.',
              textoBoton: 'Reintentar',
              onPressed: () => ref.invalidate(solicitudDetalleProvider(solicitudId)),
            ),
            data: (solicitud) => solicitud == null
                ? EstadoVacio(
                    icono: Icons.search_off_rounded,
                    titulo: 'Esta solicitud ya no está disponible',
                    mensaje: 'La trabajadora elegida o el cliente la '
                        'retiraron. Mira los otros trabajos de tus zonas.',
                    textoBoton: 'Ver trabajos disponibles',
                    onPressed: () => context.go(Rutas.inicioTrabajadora),
                  )
                : _Contenido(
                    solicitud: solicitud,
                    onPostular: () => _postular(context, ref, solicitud),
                    onSinVerificar: () => _avisarSinVerificar(context),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({
    required this.solicitud,
    required this.onPostular,
    required this.onSinVerificar,
  });

  final SolicitudDisponible solicitud;
  final VoidCallback onPostular;
  final VoidCallback onSinVerificar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    // HU-12 c2 · Si ya me postulé, el botón queda apagado.
    final misPostulaciones =
        ref.watch(misPostulacionesProvider).value ?? const <Postulacion>[];
    final yaPostulada = misPostulaciones.any(
      (p) => p.solicitudId == solicitud.id,
    );

    // HU-12 c4 · La verificación de identidad manda: sin ella no se postula.
    final identidadVerificada = PostulacionService.identidadAprobada(
      ref.watch(sesionProvider).value?.verificacion,
    );

    final productos = switch (solicitud.productosPor) {
      QuienPoneProductos.cliente => 'Los pone el cliente',
      QuienPoneProductos.trabajadora => 'Los pones tú',
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InsigniaEstado(solicitud.tipo.etiqueta, tono: TonoInsignia.azul),
              const Spacer(),
              Text(
                Formato.postulantes(solicitud.numPostulantes),
                style: textos.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recibes ${Formato.dinero(solicitud.pagoOfrecido)}',
            style: textos.headlineSmall?.copyWith(color: AppColors.primario),
          ),
          const SizedBox(height: 4),
          Text(
            'Pago por el servicio, antes de la tarifa de LimpiaYa.',
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
          const Divider(height: 32),
          _Fila(
            icono: Icons.calendar_month_outlined,
            etiqueta: 'Fecha',
            valor: Formato.fechaLarga(solicitud.inicio),
          ),
          _Fila(
            icono: Icons.schedule,
            etiqueta: 'Hora de inicio',
            valor: Formato.hora(solicitud.inicio),
          ),
          _Fila(
            icono: Icons.timelapse,
            etiqueta: 'Horas estimadas',
            valor: Formato.horas(solicitud.horasEstimadas),
          ),
          _Fila(
            icono: Icons.cleaning_services_outlined,
            etiqueta: 'Tipo de limpieza',
            valor: solicitud.tipo.etiqueta,
          ),
          _Fila(
            icono: Icons.location_on_outlined,
            etiqueta: 'Zona',
            valor: '${solicitud.zona}, Caracas',
          ),
          _Fila(
            icono: Icons.bed_outlined,
            etiqueta: 'Habitaciones',
            valor: Formato.habitaciones(solicitud.habitaciones),
          ),
          _Fila(
            icono: Icons.bathtub_outlined,
            etiqueta: 'Baños',
            valor: Formato.banos(solicitud.banos),
          ),
          _Fila(
            icono: Icons.pets_outlined,
            etiqueta: 'Mascotas',
            valor: solicitud.tieneMascotas ? 'Sí hay' : 'No hay',
          ),
          _Fila(
            icono: Icons.shopping_basket_outlined,
            etiqueta: 'Productos de limpieza',
            valor: productos,
          ),
          _Fila(
            icono: Icons.payments_outlined,
            etiqueta: 'Método de pago',
            valor: solicitud.metodoPago.etiqueta,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La dirección exacta la verás cuando el cliente te elija.',
                    style: textos.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('postularme-detalle'),
            onPressed: yaPostulada
                ? null
                : () => identidadVerificada ? onPostular() : onSinVerificar(),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(yaPostulada ? 'Ya te postulaste' : 'Postularme'),
          ),
        ],
      ),
    );
  }
}

/// Una línea del detalle: ícono, etiqueta y valor.
class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: AppColors.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              etiqueta,
              style: textos.bodyMedium?.copyWith(
                color: AppColors.textoSecundario,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            style: textos.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
        ],
      ),
    );
  }
}
