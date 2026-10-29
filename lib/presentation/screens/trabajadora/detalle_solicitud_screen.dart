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
///
/// Corrección de la revisión: la página estaba muy vacía. Ahora sigue el
/// JobDetail del Figma: en escritorio, el detalle a la izquierda y la tarjeta
/// "Lo que recibes" con el botón a la derecha; en móvil, todo en una columna
/// con el pago arriba.
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
          anchoMaximo: 1080,
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
    final movil = Responsive.esMovil(context);

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

    final pago = _TarjetaPago(
      solicitud: solicitud,
      yaPostulada: yaPostulada,
      onPostular: () => identidadVerificada ? onPostular() : onSinVerificar(),
    );

    final secciones = <Widget>[
      _Horario(solicitud: solicitud),
      const SizedBox(height: 16),
      _Casa(solicitud: solicitud),
      const SizedBox(height: 16),
      _Ubicacion(zona: solicitud.zona),
      const SizedBox(height: 16),
      _Consejos(solicitud: solicitud),
    ];

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(solicitud: solicitud),
          const SizedBox(height: 16),
          pago,
          const SizedBox(height: 16),
          ...secciones,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Encabezado(solicitud: solicitud),
              const SizedBox(height: 16),
              ...secciones,
            ],
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(width: 340, child: pago),
      ],
    );
  }
}

/// Recuadro blanco con borde, igual al de las demás tarjetas.
class _Caja extends StatelessWidget {
  const _Caja({required this.child, this.titulo});

  final String? titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null) ...[
            Text(
              titulo!,
              style: textos.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.texto,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tipo de limpieza, título y número de postulantes.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.solicitud});

  final SolicitudDisponible solicitud;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return _Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InsigniaEstado(solicitud.tipo.etiqueta, tono: TonoInsignia.azul),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: AppColors.textoSecundario,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        Formato.postulantes(solicitud.numPostulantes),
                        textAlign: TextAlign.right,
                        style: textos.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${solicitud.tipo.servicio} en ${solicitud.zona}',
            style: textos.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            solicitud.numPostulantes == 0
                ? 'Nadie se ha postulado todavía: sé la primera.'
                : 'El cliente elegirá entre las trabajadoras que se postulen.',
            style: textos.bodyMedium?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fecha, hora de inicio y duración en tres bloques.
class _Horario extends StatelessWidget {
  const _Horario({required this.solicitud});

  final SolicitudDisponible solicitud;

  @override
  Widget build(BuildContext context) {
    final fin = Formato.horaFin(solicitud.inicio, solicitud.horasEstimadas);
    final articulo = fin.startsWith('1:') ? 'la' : 'las';
    final bloques = [
      _Dato(
        icono: Icons.calendar_month_outlined,
        etiqueta: 'Fecha',
        valor: Formato.fechaLarga(solicitud.inicio),
      ),
      _Dato(
        icono: Icons.schedule,
        etiqueta: 'Hora de inicio',
        valor: Formato.hora(solicitud.inicio),
        nota: 'Termina cerca de $articulo $fin',
      ),
      _Dato(
        icono: Icons.timelapse,
        etiqueta: 'Horas estimadas',
        valor: Formato.horas(solicitud.horasEstimadas),
      ),
    ];

    return _Caja(
      titulo: 'Cuándo',
      child: _Rejilla(children: bloques),
    );
  }
}

/// Cómo es la casa y quién lleva los productos.
class _Casa extends StatelessWidget {
  const _Casa({required this.solicitud});

  final SolicitudDisponible solicitud;

  @override
  Widget build(BuildContext context) {
    final productos = switch (solicitud.productosPor) {
      QuienPoneProductos.cliente => 'Los pone el cliente',
      QuienPoneProductos.trabajadora => 'Los pones tú',
    };

    return _Caja(
      titulo: 'La casa',
      child: _Rejilla(
        children: [
          _Dato(
            icono: Icons.cleaning_services_outlined,
            etiqueta: 'Tipo de limpieza',
            valor: solicitud.tipo.etiqueta,
          ),
          _Dato(
            icono: Icons.bed_outlined,
            etiqueta: 'Habitaciones',
            valor: Formato.habitaciones(solicitud.habitaciones),
          ),
          _Dato(
            icono: Icons.bathtub_outlined,
            etiqueta: 'Baños',
            valor: Formato.banos(solicitud.banos),
          ),
          _Dato(
            icono: Icons.pets_outlined,
            etiqueta: 'Mascotas',
            valor: solicitud.tieneMascotas ? 'Sí hay' : 'No hay',
          ),
          _Dato(
            icono: Icons.shopping_basket_outlined,
            etiqueta: 'Productos de limpieza',
            valor: productos,
          ),
        ],
      ),
    );
  }
}

/// Zona y el aviso de privacidad de la dirección (HU-45 c2).
class _Ubicacion extends StatelessWidget {
  const _Ubicacion({required this.zona});

  final String zona;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return _Caja(
      titulo: 'Dónde',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Dato(
            icono: Icons.location_on_outlined,
            etiqueta: 'Zona',
            valor: '$zona, Caracas',
          ),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

/// Lo que conviene saber antes de postularse (ayuda, heurística 10).
class _Consejos extends StatelessWidget {
  const _Consejos({required this.solicitud});

  final SolicitudDisponible solicitud;

  @override
  Widget build(BuildContext context) {
    final consejos = [
      'Revisa que el horario no choque con otro trabajo tuyo.',
      if (solicitud.productosPor == QuienPoneProductos.trabajadora)
        'En este trabajo llevas tú los productos de limpieza.',
      if (solicitud.tieneMascotas)
        'En la casa hay mascotas: tenlo en cuenta si tienes alergias.',
      'Mientras tu postulación esté pendiente puedes retirarla desde '
          'Mis servicios.',
    ];
    final textos = Theme.of(context).textTheme;

    return _Caja(
      titulo: 'Antes de postularte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final consejo in consejos)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppColors.primario,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(consejo, style: textos.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta "Lo que recibes" con el botón Postularme (Figma applyCard).
class _TarjetaPago extends StatelessWidget {
  const _TarjetaPago({
    required this.solicitud,
    required this.yaPostulada,
    required this.onPostular,
  });

  final SolicitudDisponible solicitud;
  final bool yaPostulada;
  final VoidCallback onPostular;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return _Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LO QUE RECIBES',
            style: textos.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recibes ${Formato.dinero(solicitud.pagoOfrecido)}',
            style: textos.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pago por el servicio, antes de la tarifa de LimpiaYa.',
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
          const Divider(height: 28),
          _Fila(
            icono: Icons.payments_outlined,
            etiqueta: 'Método de pago',
            valor: solicitud.metodoPago.etiqueta,
          ),
          _Fila(
            icono: Icons.timelapse,
            etiqueta: 'Equivale a',
            valor: Formato.porHora(
              solicitud.pagoOfrecido,
              solicitud.horasEstimadas,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('postularme-detalle'),
            onPressed: yaPostulada ? null : onPostular,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(yaPostulada ? 'Ya te postulaste' : 'Postularme'),
          ),
          const SizedBox(height: 10),
          Text(
            yaPostulada
                ? 'Te avisaremos cuando el cliente elija.'
                : 'Puedes dejarle un mensaje al cliente antes de enviar.',
            textAlign: TextAlign.center,
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloques de datos: dos o tres por fila según el ancho disponible.
class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 480 ? 3 : 2;
        const espacio = 12.0;
        final ancho =
            (restricciones.maxWidth - espacio * (columnas - 1)) / columnas;
        return Wrap(
          spacing: espacio,
          runSpacing: 16,
          children: [
            for (final hijo in children) SizedBox(width: ancho, child: hijo),
          ],
        );
      },
    );
  }
}

/// Un dato con ícono, etiqueta pequeña arriba y valor en negrita.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.nota,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Row(
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: textos.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.texto,
                ),
              ),
              if (nota != null) ...[
                const SizedBox(height: 2),
                Text(
                  nota!,
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Una línea de la tarjeta de pago: ícono, etiqueta y valor.
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
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: textos.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
