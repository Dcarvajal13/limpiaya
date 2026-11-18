import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_postulacion.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/postulante.dart';
import '../../../domain/entities/solicitud.dart';
import '../../../domain/services/servicio_service.dart';
import '../../providers/elegir_trabajadora_provider.dart';
import '../../providers/mis_solicitudes_provider.dart';
import '../../providers/postulantes_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';
import '../../widgets/desglose_costo.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_destacada.dart';
import '../../widgets/insignia_estado.dart';
import 'barra_cliente.dart';

/// HU-14 · Ver las postulantes de mi solicitud.
///
/// Criterios de aceptación:
/// 1. Cada postulante con su foto, nombre, calificación promedio, insignia
///    "Identidad verificada" y el mensaje que dejó.
/// 2. Si una postulante se retiró (HU-26), ya no aparece.
/// 3. Sin postulantes, se muestra "Todavía no hay postulantes".
/// 4. Al tocar a una, se abre su perfil público (HU-06).
///
/// HU-15 · Elegir a una trabajadora: cada postulante pendiente tiene el
/// botón "Elegir". Al confirmar, la solicitud queda Asignada (c1), las demás
/// pasan a No seleccionada (c2) y el botón deja de ofrecerse (c4).
class PostulantesScreen extends ConsumerWidget {
  const PostulantesScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final movil = Responsive.esMovil(context);
    final postulantes = ref.watch(postulantesProvider(solicitudId));

    // Resumen de la solicitud (H6: recordar cuál es sin tener que volver).
    final solicitud = ref.watch(misSolicitudesProvider).maybeWhen(
          data: (lista) {
            for (final s in lista) {
              if (s.id == solicitudId) return s;
            }
            return null;
          },
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          BarraCliente(
            nombre: sesion?.nombre ?? '',
            fotoUrl: sesion?.fotoUrl,
          ),
          Expanded(
            child: DesplazableConPie(
              child: ContenidoCentrado(
                vertical: movil ? 16 : 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Encabezado(
                      onVolver: () => context.go(Rutas.inicioCliente),
                      onActualizar: () =>
                          ref.invalidate(postulantesProvider(solicitudId)),
                    ),
                    const SizedBox(height: 20),
                    if (solicitud != null) ...[
                      _ResumenSolicitud(solicitud: solicitud),
                      const SizedBox(height: 24),
                    ],
                    ...postulantes.when(
                      loading: () => const [
                        _Caja(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ],
                      error: (error, _) => [
                        _Caja(
                          child: EstadoVacio(
                            icono: Icons.wifi_off_rounded,
                            titulo: error is AppException
                                ? error.mensaje
                                : 'No pudimos cargar las postulantes.',
                            textoBoton: 'Reintentar',
                            onPressed: () => ref
                                .invalidate(postulantesProvider(solicitudId)),
                          ),
                        ),
                      ],
                      data: (lista) => lista.isEmpty
                          ? [
                              // HU-14 c3
                              const _Caja(
                                child: EstadoVacio(
                                  icono: Icons.hourglass_empty_rounded,
                                  titulo: 'Todavía no hay postulantes',
                                  mensaje: 'Cuando una trabajadora de tu zona '
                                      'se postule, la verás aquí.',
                                ),
                              ),
                            ]
                          : [
                              Text(
                                _titulo(lista),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primarioOscuro,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _Cuadricula(
                                hijos: [
                                  for (final p in lista)
                                    _TarjetaPostulante(
                                      postulante: p,
                                      // HU-14 c4: abre su perfil público (HU-06).
                                      onTap: () => context.push(
                                        Rutas.perfilPublicoTrabajadora(
                                          p.trabajadoraId,
                                        ),
                                      ),
                                      elegida: p.estado ==
                                          EstadoPostulacion.aceptada,
                                      // HU-15 c1 y c4: solo mientras se
                                      // puede elegir.
                                      onElegir: ServicioService.puedeElegir(
                                        postulante: p,
                                        postulantes: lista,
                                        estadoSolicitud: solicitud?.estado,
                                      )
                                          ? () => _elegir(
                                                context,
                                                ref,
                                                solicitudId: solicitudId,
                                                postulante: p,
                                                solicitud: solicitud,
                                              )
                                          : null,
                                    ),
                                ],
                              ),
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

/// "2 trabajadoras se postularon", o "Trabajadora elegida" cuando ya se
/// eligió a una (HU-15): las demás dejan de listarse porque quedaron como
/// No seleccionada.
String _titulo(List<Postulante> lista) {
  if (lista.any((p) => p.estado == EstadoPostulacion.aceptada)) {
    return 'Trabajadora elegida';
  }
  return lista.length == 1
      ? '1 trabajadora se postuló'
      : '${lista.length} trabajadoras se postularon';
}

/// HU-15 · Pide confirmación y elige a la postulante. Con "No" no cambia
/// nada. Al terminar refresca la lista (c4: el botón desaparece) y Mis
/// solicitudes (la tarjeta pasa a Asignada).
Future<void> _elegir(
  BuildContext context,
  WidgetRef ref, {
  required String solicitudId,
  required Postulante postulante,
  Solicitud? solicitud,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => _DialogoElegir(
      postulante: postulante,
      solicitud: solicitud,
    ),
  );
  if (confirmado != true || !context.mounted) return;

  final error = await ref
      .read(elegirTrabajadoraProvider.notifier)
      .elegir(postulante.postulacionId);
  if (!context.mounted) return;

  // Haya salido bien o no, la lista pudo cambiar (alguien se retiró, la
  // solicitud se asignó en otra pestaña…): se vuelve a cargar.
  ref.invalidate(postulantesProvider(solicitudId));
  ref.invalidate(misSolicitudesProvider);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          error ?? ServicioService.mensajeElegida(postulante.nombre),
        ),
      ),
    );
}

/// Confirmación antes de elegir (H5 del taller: diálogo antes de una acción
/// que no se puede deshacer).
class _DialogoElegir extends StatelessWidget {
  const _DialogoElegir({required this.postulante, this.solicitud});

  final Postulante postulante;
  final Solicitud? solicitud;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final nombre = postulante.nombre.trim().split(RegExp(r'\s+')).first;
    final fecha = solicitud == null
        ? 'El servicio'
        : 'El servicio del ${Formato.diaDeMes(solicitud!.inicio)}';

    return AlertDialog(
      title: Text('¿Elegir a ${postulante.nombre}?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$fecha quedará agendado con ella. $nombre verá tu dirección '
              'exacta y el punto de referencia para llegar.',
              style: textos.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Si hay más postulantes, verán que elegiste a otra persona.',
              style: textos.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('cancelar-elegir'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        FilledButton(
          key: const Key('confirmar-elegir'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sí, elegir'),
        ),
      ],
    );
  }
}

/// Cuadrícula de tarjetas: 3 por fila en pantallas grandes, 2 en medianas
/// y 1 en el teléfono (mismo criterio que Mis solicitudes).
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.hijos});

  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;
        final columnas = ancho >= 1100
            ? 3
            : ancho >= 700
                ? 2
                : 1;
        const espacio = 16.0;
        final anchoTarjeta = (ancho - espacio * (columnas - 1)) / columnas;

        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (final hijo in hijos)
              SizedBox(width: anchoTarjeta, child: hijo),
          ],
        );
      },
    );
  }
}

/// "← Mis solicitudes", título, subtítulo y botón de actualizar.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onVolver, required this.onActualizar});

  final VoidCallback onVolver;
  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onVolver,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Mis solicitudes'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primario),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'Postulantes',
                style: textos.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primarioOscuro,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: onActualizar,
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.primario,
            ),
          ],
        ),
        Text(
          'Compara a quienes se postularon antes de elegir.',
          style: textos.bodyLarge?.copyWith(color: AppColors.textoSecundario),
        ),
      ],
    );
  }
}

/// Tarjeta con los datos de la solicitud, como en Mis solicitudes.
class _ResumenSolicitud extends StatelessWidget {
  const _ResumenSolicitud({required this.solicitud});

  final Solicitud solicitud;

  TonoInsignia _tono(EstadoSolicitud estado) => switch (estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final s = solicitud;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TU SOLICITUD',
            style: textos.labelSmall?.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w800,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InsigniaEstado(s.estado.etiqueta, tono: _tono(s.estado)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Limpieza ${s.tipo.etiqueta.toLowerCase()}',
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formato.diaCompletoHora(s.inicio),
            style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textoSecundario,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${s.zona} · ${Formato.horas(s.horasEstimadas)} · '
                  '${Formato.dinero(s.pagoOfrecido)}',
                  style: textos.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // HU-52 c3: el desglose también en el resumen de la solicitud.
          const SizedBox(height: 6),
          DesgloseCosto(pago: s.pagoOfrecido),
        ],
      ),
    );
  }
}
/// Tarjeta de una postulante (HU-14 c1), con el sello de confianza:
/// verificación + reputación + experiencia. Formato de cuadrícula:
/// franja de color con foto y nombre, datos en el medio y el mensaje abajo.
/// Sin sombra, como pide el manual de marca: el color la separa del fondo.
class _TarjetaPostulante extends StatelessWidget {
  const _TarjetaPostulante({
    required this.postulante,
    required this.onTap,
    this.onElegir,
    this.elegida = false,
  });

  final Postulante postulante;
  final VoidCallback onTap;

  /// HU-15 · Elegir a esta postulante. Null si ya no se puede elegir (c4).
  final VoidCallback? onElegir;

  /// HU-15 · Es la trabajadora que el cliente eligió.
  final bool elegida;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final p = postulante;
    final datos = _datosDeExperiencia(p);
    final mensaje = p.mensaje?.trim();
    final sinMensaje = mensaje == null || mensaje.isEmpty;

    return Material(
      color: AppColors.superficie,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja superior de color: foto, nombre y reputación.
              Container(
                color: AppColors.primarioClaro.withValues(alpha: 0.45),
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.superficie,
                      foregroundImage:
                          p.fotoUrl == null ? null : NetworkImage(p.fotoUrl!),
                      child: Text(
                        _iniciales(p.nombre),
                        style: textos.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primarioOscuro,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombre,
                            style: textos.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primarioOscuro,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _reputacion(p),
                            style: textos.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.texto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primarioOscuro,
                    ),
                  ],
                ),
              ),
              // Cuerpo blanco: insignia, experiencia y mensaje.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HU-61 · "Destacada" junto a la verificación.
                    if (p.verificada || p.destacada)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (p.destacada) const InsigniaDestacada(),
                          if (p.verificada) const _InsigniaVerificada(),
                        ],
                      ),
                    if (datos != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        datos,
                        style: textos.bodySmall?.copyWith(
                          color: AppColors.textoSecundario,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // El mensaje que dejó, como una cita.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.fondo,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppColors.primario, width: 3),
                        ),
                      ),
                      child: Text(
                        sinMensaje ? 'No dejó un mensaje.' : '“$mensaje”',
                        style: textos.bodyMedium?.copyWith(
                          fontStyle:
                              sinMensaje ? FontStyle.italic : FontStyle.normal,
                          color: sinMensaje
                              ? AppColors.textoSecundario
                              : AppColors.texto,
                        ),
                      ),
                    ),
                    if (elegida) ...[
                      const SizedBox(height: 14),
                      const InsigniaEstado(
                        'Elegida',
                        tono: TonoInsignia.verde,
                      ),
                    ] else if (onElegir != null) ...[
                      const SizedBox(height: 14),
                      FilledButton(
                        key: Key('elegir-${p.postulacionId}'),
                        onPressed: onElegir,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: AppColors.primarioOscuro,
                        ),
                        child: Text('Elegir a ${_primerNombre(p.nombre)}'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _primerNombre(String nombre) =>
      nombre.trim().split(RegExp(r'\s+')).first;

  /// "★ 4,8 · 3 reseñas" o "Nueva en la plataforma".
  String _reputacion(Postulante p) {
    if (p.promedio == null) return 'Nueva en la plataforma';
    final promedio = p.promedio!.toStringAsFixed(1).replaceAll('.', ',');
    if (p.totalResenas <= 0) return '★ $promedio';
    final resenas =
        p.totalResenas == 1 ? '1 reseña' : '${p.totalResenas} reseñas';
    return '★ $promedio · $resenas';
  }

  /// "5 años de experiencia · 12 servicios completados", o null si no hay datos.
  String? _datosDeExperiencia(Postulante p) {
    final partes = <String>[
      if (p.experienciaAnios != null && p.experienciaAnios! > 0)
        p.experienciaAnios == 1
            ? '1 año de experiencia'
            : '${p.experienciaAnios} años de experiencia',
      if (p.serviciosCompletados > 0)
        p.serviciosCompletados == 1
            ? '1 servicio completado'
            : '${p.serviciosCompletados} servicios completados',
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final letras = [
      for (final parte in partes.take(2))
        if (parte.isNotEmpty) parte[0].toUpperCase(),
    ];
    return letras.isEmpty ? '?' : letras.join();
  }
}
/// Insignia "Identidad verificada" con los colores de la marca.
class _InsigniaVerificada extends StatelessWidget {
  const _InsigniaVerificada();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarioClaro.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 15,
            color: AppColors.primarioOscuro,
          ),
          SizedBox(width: 5),
          Text(
            'Identidad verificada',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primarioOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenedor blanco con borde para la carga, el error o la lista vacía.
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