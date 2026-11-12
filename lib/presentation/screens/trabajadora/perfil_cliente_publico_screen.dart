import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/perfil_cliente_publico.dart';
import '../../../domain/services/reputacion_service.dart';
import '../../providers/perfil_cliente_publico_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/estrellas.dart';
import '../../widgets/resena_item.dart';

/// HU-46 · Perfil de un cliente, visto por la trabajadora.
///
/// Criterio 3: al tocar el nombre del cliente en el detalle de la solicitud
/// se abre esta pantalla con las reseñas que le dejaron otras trabajadoras.
/// Nunca muestra teléfono, correo ni dirección.
class PerfilClientePublicoScreen extends ConsumerWidget {
  const PerfilClientePublicoScreen({super.key, required this.clienteId});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movil = Responsive.esMovil(context);
    final perfil = ref.watch(perfilClientePublicoProvider(clienteId));

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Rutas.inicioTrabajadora),
        ),
        title: const Text('Perfil del cliente'),
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
                  : 'No pudimos cargar el perfil del cliente.',
              textoBoton: 'Reintentar',
              onPressed: () =>
                  ref.invalidate(perfilClientePublicoProvider(clienteId)),
            ),
            data: (datos) => datos == null
                ? const EstadoVacio(
                    icono: Icons.person_off_outlined,
                    titulo: 'No encontramos a este cliente',
                    mensaje: 'Puede que ya no tenga cuenta en LimpiaYa.',
                  )
                : _Contenido(perfil: datos, movil: movil),
          ),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.perfil, required this.movil});

  final PerfilClientePublico perfil;
  final bool movil;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final p = perfil;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caja(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUsuario(
                nombre: p.nombre,
                fotoUrl: p.fotoUrl,
                tamano: movil ? 64 : 80,
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
                    const SizedBox(height: 8),
                    if (p.esNuevo)
                      Text(
                        ReputacionService.clienteNuevo,
                        style: textos.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textoSecundario,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Estrellas(valor: p.promedio!, tamano: 18),
                          Text(
                            ReputacionService.promedio(p.promedio!),
                            style: textos.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '· ${ReputacionService.resenas(p.totalResenas)}',
                            style: textos.bodySmall,
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.task_alt_rounded,
                          size: 18,
                          color: AppColors.primario,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            ReputacionService.servicios(
                              p.serviciosCompletados,
                            ),
                            style: textos.bodyMedium?.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Caja(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lo que dicen otras trabajadoras',
                style: textos.titleMedium,
              ),
              const SizedBox(height: 12),
              if (p.resenas.isEmpty)
                Text(
                  'Todavía no hay reseñas para mostrar.',
                  style:
                      textos.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                )
              else
                for (final (i, resena) in p.resenas.indexed) ...[
                  if (i > 0) const Divider(height: 24, color: AppColors.borde),
                  ResenaItem(resena: resena),
                ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 16,
              color: AppColors.textoSecundario,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Su teléfono y su dirección no se muestran aquí. La dirección '
                'la verás cuando te elija.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
