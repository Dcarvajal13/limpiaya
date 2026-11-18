import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/perfil_publico.dart';
import '../../providers/perfil_publico_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/estrellas.dart';
import '../../widgets/insignia_destacada.dart';
import '../../widgets/insignia_verificada.dart';
import '../../widgets/resena_item.dart';

/// HU-06 · Ver el perfil público de una trabajadora.
///
/// Criterios de aceptación:
/// 1. Foto, zonas, servicios, años de experiencia, insignia "Identidad
///    verificada", promedio y reseñas.
/// 2. Sin reseñas se muestra "Aún no tiene reseñas" en vez del promedio.
/// 3. Nunca aparecen su teléfono ni su correo (la vista pública no los trae).
class PerfilPublicoScreen extends ConsumerWidget {
  const PerfilPublicoScreen({super.key, required this.trabajadoraId});

  final String trabajadoraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movil = Responsive.esMovil(context);
    final perfil = ref.watch(perfilPublicoProvider(trabajadoraId));

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        // Siempre hay forma de volver: si se abrió con un enlace directo no
        // queda nada en la pila, así que se manda al inicio del rol.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Rutas.inicioCliente),
        ),
        title: const Text('Perfil'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borde),
        ),
      ),
      body: DesplazableConPie(
        child: ContenidoCentrado(
          vertical: movil ? 16 : 28,
          child: perfil.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => EstadoVacio(
              icono: Icons.wifi_off_rounded,
              titulo: error is AppException
                  ? error.mensaje
                  : 'No pudimos cargar el perfil.',
              textoBoton: 'Reintentar',
              onPressed: () =>
                  ref.invalidate(perfilPublicoProvider(trabajadoraId)),
            ),
            data: (datos) {
              if (datos == null) {
                return const EstadoVacio(
                  icono: Icons.person_off_outlined,
                  titulo: 'No encontramos esta trabajadora',
                  mensaje: 'Puede que ya no tenga cuenta en LimpiaYa.',
                );
              }
              return _Contenido(perfil: datos, movil: movil);
            },
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.perfil, required this.movil});

  final PerfilPublico perfil;
  final bool movil;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final p = perfil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caja(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarUsuario(
                    nombre: p.nombre,
                    fotoUrl: p.fotoUrl,
                    tamano: movil ? 72 : 88,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          style: textos.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (p.verificada) ...[
                          const SizedBox(height: 6),
                          const InsigniaVerificada(),
                        ],
                        // HU-61 · Insignia "Destacada".
                        if (p.destacada) ...[
                          const SizedBox(height: 8),
                          const InsigniaDestacada(),
                        ],
                        const SizedBox(height: 10),
                        _Reputacion(perfil: p),
                      ],
                    ),
                  ),
                ],
              ),
              if (p.descripcion != null && p.descripcion!.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Sobre mí', style: textos.titleMedium),
                const SizedBox(height: 6),
                Text(
                  p.descripcion!.trim(),
                  style: textos.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _Dato(
                    icono: Icons.workspace_premium_outlined,
                    texto: p.experienciaAnios == null
                        ? 'Experiencia sin indicar'
                        : (p.experienciaAnios == 1
                            ? '1 año de experiencia'
                            : '${p.experienciaAnios} años de experiencia'),
                  ),
                  if (p.tarifaReferencia != null)
                    _Dato(
                      icono: Icons.payments_outlined,
                      texto:
                          'Desde ${Formato.dinero(p.tarifaReferencia!)} por hora',
                    ),
                  _Dato(
                    icono: Icons.task_alt_rounded,
                    texto: p.serviciosCompletados == 1
                        ? '1 servicio completado'
                        : '${p.serviciosCompletados} servicios completados',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (p.servicios.isNotEmpty) ...[
          _Caja(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Servicios que ofrece', style: textos.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final servicio in p.servicios)
                      Chip(
                        label: Text(servicio.servicio),
                        labelStyle: textos.labelMedium?.copyWith(fontSize: 13),
                        backgroundColor: AppColors.primarioClaro,
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (p.zonas.isNotEmpty) ...[
          _Caja(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zonas donde trabaja', style: textos.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final zona in p.zonas)
                      Chip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.primario,
                        ),
                        label: Text(zona),
                        labelStyle: textos.labelMedium?.copyWith(fontSize: 13),
                        backgroundColor: AppColors.fondo,
                        side: const BorderSide(color: AppColors.borde),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _Caja(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reseñas', style: textos.titleMedium),
              const SizedBox(height: 12),
              if (p.resenas.isEmpty)
                Text(
                  'Todavía no hay reseñas para mostrar.',
                  style: textos.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                )
              else
                for (final (i, resena) in p.resenas.indexed) ...[
                  if (i > 0) const Divider(height: 24, color: AppColors.borde),
                  // HU-31 c1 · Con la respuesta de ella debajo, si respondió.
                  ResenaItem(
                    resena: resena,
                    etiquetaRespuesta: 'Respuesta de ${_primerNombre(p.nombre)}',
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

/// Promedio (★ 4,9 · 12 reseñas) o "Aún no tiene reseñas" (c2).
class _Reputacion extends StatelessWidget {
  const _Reputacion({required this.perfil});

  final PerfilPublico perfil;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    if (!perfil.tieneResenas) {
      return Text(
        'Aún no tiene reseñas',
        style: textos.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Estrellas(valor: perfil.promedio!, tamano: 18),
        Text(
          Formato.promedio(perfil.promedio!),
          style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          perfil.totalResenas == 1
              ? '· 1 reseña'
              : '· ${perfil.totalResenas} reseñas',
          style: textos.bodySmall,
        ),
      ],
    );
  }
}

String _primerNombre(String nombre) =>
    nombre.trim().split(RegExp(r'\s+')).first;

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 18, color: AppColors.primario),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
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
