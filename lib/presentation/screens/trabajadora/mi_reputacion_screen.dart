import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/mi_reputacion.dart';
import '../../../domain/entities/perfil_publico.dart';
import '../../../domain/services/nivel_service.dart';
import '../../../domain/services/reputacion_service.dart';
import '../../../domain/services/respuesta_service.dart';
import '../../providers/mi_reputacion_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/dialogo_responder.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/estrellas.dart';
import '../../widgets/insignia_destacada.dart';
import '../../widgets/resena_item.dart';
import 'barra_trabajadora.dart';

/// "Mi reputación" de la trabajadora ('/trabajadora/reputacion').
///
/// HU-61 · Subir de nivel: muestra la insignia "Destacada" o lo que le falta
/// para conseguirla.
///
/// HU-31 · Responder a una reseña:
/// 1. Escribe una respuesta, la publica y aparece debajo de la reseña (aquí
///    y en su perfil público).
/// 2. Si ya respondió, el botón cambia a "Editar respuesta": puede cambiarla
///    pero no agregar otra.
/// 3. Más de 300 caracteres: ve el límite y no se publica.
class MiReputacionScreen extends ConsumerWidget {
  const MiReputacionScreen({super.key});

  Future<void> _responder(
    BuildContext context,
    WidgetRef ref,
    ResenaPublica resena,
  ) async {
    final editaba = resena.tieneRespuesta;
    final guardada = await mostrarDialogoResponder(context, resena: resena);
    if (guardada != true || !context.mounted) return;

    ref.invalidate(miReputacionProvider);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            editaba
                ? RespuestaService.mensajeEditada
                : RespuestaService.mensajePublicada,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final reputacion = ref.watch(miReputacionProvider);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          BarraTrabajadora(
            nombre: sesion?.nombre ?? '',
            fotoUrl: sesion?.fotoUrl,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 20 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mi reputación',
                      style:
                          (movil ? textos.headlineLarge : textos.displaySmall)
                              ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lo que los clientes dicen de tu trabajo.',
                      style: textos.bodyLarge
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    reputacion.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _Caja(
                        child: EstadoVacio(
                          icono: Icons.wifi_off_rounded,
                          titulo: error is AppException
                              ? error.mensaje
                              : 'No pudimos cargar tu reputación.',
                          textoBoton: 'Reintentar',
                          onPressed: () => ref.invalidate(miReputacionProvider),
                        ),
                      ),
                      data: (datos) => _Contenido(
                        datos: datos,
                        onResponder: (resena) =>
                            _responder(context, ref, resena),
                      ),
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

class _Contenido extends StatelessWidget {
  const _Contenido({required this.datos, required this.onResponder});

  final MiReputacion datos;
  final ValueChanged<ResenaPublica> onResponder;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Resumen(datos: datos),
        const SizedBox(height: 16),
        _Nivel(datos: datos),
        const SizedBox(height: 16),
        _Caja(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reseñas que te dejaron', style: textos.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Una reseña aparece cuando tú y el cliente califican, o '
                'cuando pasan 7 días.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
              const SizedBox(height: 16),
              if (datos.resenas.isEmpty)
                Text(
                  'Todavía no tienes reseñas visibles.',
                  style:
                      textos.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                )
              else
                for (final (i, resena) in datos.resenas.indexed) ...[
                  if (i > 0) const Divider(height: 28, color: AppColors.borde),
                  ResenaItem(
                    resena: resena,
                    etiquetaRespuesta: 'Tu respuesta',
                    pie: resena.id == null
                        ? null
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              key: Key('responder-${resena.id}'),
                              onPressed: () => onResponder(resena),
                              icon: Icon(
                                resena.tieneRespuesta
                                    ? Icons.edit_outlined
                                    : Icons.reply_rounded,
                                size: 18,
                              ),
                              label: Text(
                                resena.tieneRespuesta
                                    ? 'Editar respuesta'
                                    : 'Responder',
                              ),
                            ),
                          ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Promedio, reseñas y servicios completados.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.datos});

  final MiReputacion datos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final promedio = datos.promedio;

    final bloques = [
      _Cifra(
        valor: promedio == null ? '—' : ReputacionService.promedio(promedio),
        etiqueta: promedio == null ? 'Aún sin promedio' : 'Promedio',
        extra: promedio == null ? null : Estrellas(valor: promedio, tamano: 16),
      ),
      _Cifra(
        valor: '${datos.totalResenas}',
        etiqueta: datos.totalResenas == 1 ? 'Reseña' : 'Reseñas',
      ),
      _Cifra(
        valor: '${datos.serviciosCompletados}',
        etiqueta: datos.serviciosCompletados == 1
            ? 'Servicio completado'
            : 'Servicios completados',
      ),
    ];

    return _Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen', style: textos.titleMedium),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, bloque) in bloques.indexed) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: bloque),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// HU-61 · La insignia "Destacada" o lo que falta para conseguirla.
class _Nivel extends StatelessWidget {
  const _Nivel({required this.datos});

  final MiReputacion datos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final destacada = datos.destacada;

    return _Caja(
      child: Column(
        key: const Key('mi-nivel'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                destacada ? 'Eres una trabajadora destacada' : 'Sube de nivel',
                style: textos.titleMedium,
              ),
              if (destacada) const InsigniaDestacada(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            destacada
                ? 'Apareces primero cuando un cliente ve sus postulantes. '
                    'Mantén tu promedio en 4,5 o más para no perder la '
                    'insignia.'
                : 'Consigue la insignia "${NivelService.nombreInsignia}". '
                    '${NivelService.explicacion}',
            style: textos.bodySmall?.copyWith(
              color: AppColors.textoSecundario,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _Requisito(
            cumplido: datos.cumpleServicios,
            texto: NivelService.progresoServicios(datos.serviciosCompletados),
          ),
          _Requisito(
            cumplido: datos.cumplePromedio,
            texto: NivelService.progresoPromedio(datos.promedio),
          ),
          _Requisito(
            cumplido: datos.cumpleCancelaciones,
            texto: NivelService.progresoCancelaciones(
              datos.cancelacionesTardias,
            ),
          ),
        ],
      ),
    );
  }
}

class _Requisito extends StatelessWidget {
  const _Requisito({required this.cumplido, required this.texto});

  final bool cumplido;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cumplido
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: cumplido ? AppColors.exito : AppColors.textoSecundario,
            semanticLabel: cumplido ? 'Cumplido' : 'Pendiente',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cumplido ? AppColors.texto : AppColors.textoSecundario,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta, this.extra});

  final String valor;
  final String etiqueta;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          style: textos.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primario,
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: 2),
          extra!,
        ],
        const SizedBox(height: 2),
        Text(
          etiqueta,
          style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
        ),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: child,
    );
  }
}
