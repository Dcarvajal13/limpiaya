import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/perfil_cliente_publico.dart';
import '../../../domain/services/reputacion_service.dart';
import '../../providers/perfil_cliente_publico_provider.dart';
import '../../widgets/avatar_usuario.dart';

/// HU-46 · Quién publicó la solicitud y qué tal cliente es.
///
/// Va en el detalle de la solicitud (HU-45):
/// 1. Si el cliente tiene calificaciones: "★ 4,8 · 3 servicios completados".
/// 2. Si no tiene: "Cliente nuevo".
/// 3. Al tocar su nombre se abre su perfil con las reseñas que le dejaron
///    otras trabajadoras.
class CajaCliente extends ConsumerWidget {
  const CajaCliente({super.key, required this.clienteId});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilClientePublicoProvider(clienteId));
    final textos = Theme.of(context).textTheme;

    final Widget contenido = perfil.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      // Es información complementaria: si falla, el detalle sigue sirviendo.
      error: (_, _) => Text(
        'No pudimos cargar la reputación del cliente.',
        style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
      ),
      data: (datos) => datos == null
          ? Text(
              'No encontramos los datos del cliente.',
              style:
                  textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
            )
          : _Cliente(perfil: datos),
    );

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
          Text(
            'El cliente',
            style: textos.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 12),
          contenido,
        ],
      ),
    );
  }
}

class _Cliente extends StatelessWidget {
  const _Cliente({required this.perfil});

  final PerfilClientePublico perfil;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final reputacion = ReputacionService.cliente(
      promedio: perfil.promedio,
      totalResenas: perfil.totalResenas,
      serviciosCompletados: perfil.serviciosCompletados,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('abrir-perfil-cliente'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Rutas.perfilClientePublico(perfil.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AvatarUsuario(
                nombre: perfil.nombre,
                fotoUrl: perfil.fotoUrl,
                tamano: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textos.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primario,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reputacion,
                      style: textos.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: perfil.esNuevo
                            ? AppColors.textoSecundario
                            : AppColors.texto,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
