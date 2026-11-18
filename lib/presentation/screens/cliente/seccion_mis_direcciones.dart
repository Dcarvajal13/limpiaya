import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/direccion_guardada.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/direcciones_service.dart';
import '../../providers/direcciones_provider.dart';
import 'dialogo_direccion.dart';

/// "Mis direcciones" en el perfil del cliente: ver, agregar, editar y
/// eliminar las direcciones que elige al publicar una solicitud.
class SeccionMisDirecciones extends ConsumerWidget {
  const SeccionMisDirecciones({super.key, required this.zonas});

  /// Catálogo de zonas, para el selector del diálogo.
  final List<Zona> zonas;

  Future<void> _agregar(
    BuildContext context,
    List<DireccionGuardada> existentes,
  ) async {
    final guardada = await mostrarDialogoDireccion(
      context,
      zonas: zonas,
      existentes: existentes,
    );
    if (guardada && context.mounted) _avisar(context, 'Dirección guardada');
  }

  Future<void> _editar(
    BuildContext context,
    List<DireccionGuardada> existentes,
    DireccionGuardada direccion,
  ) async {
    final guardada = await mostrarDialogoDireccion(
      context,
      zonas: zonas,
      existentes: existentes,
      actual: direccion,
    );
    if (guardada && context.mounted) _avisar(context, 'Dirección actualizada');
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    DireccionGuardada direccion,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar «${direccion.nombre}»?'),
        content: const Text(
          'Ya no aparecerá al publicar. Tus solicitudes publicadas no cambian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const Key('confirmar-eliminar-direccion'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    final error =
        await ref.read(direccionesProvider.notifier).eliminar(direccion.id);
    if (!context.mounted) return;
    _avisar(context, error ?? 'Dirección eliminada');
  }

  void _avisar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final resultado = ref.watch(misDireccionesProvider);
    final lista = resultado.value ?? const <DireccionGuardada>[];
    final puedeAgregar =
        !resultado.isLoading && DireccionesService.puedeAgregar(lista);

    return Container(
      key: const Key('mis-direcciones'),
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis direcciones',
                      style: textos.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Elígelas con un toque al publicar una solicitud.',
                      style: textos.bodySmall
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                key: const Key('agregar-direccion'),
                onPressed: puedeAgregar ? () => _agregar(context, lista) : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (resultado.isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (resultado.hasError)
            Row(
              children: [
                Expanded(
                  child: Text(
                    resultado.error is AppException
                        ? (resultado.error! as AppException).mensaje
                        : DireccionesService.errorCargar,
                    style: textos.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(misDireccionesProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else if (lista.isEmpty)
            Text(
              'Aún no tienes direcciones guardadas. Agrega tu casa u otro '
              'lugar donde pidas limpieza.',
              style: textos.bodyMedium
                  ?.copyWith(color: AppColors.textoSecundario),
            )
          else
            for (final d in lista)
              FilaDireccion(
                key: Key('direccion-${d.id}'),
                direccion: d,
                onEditar: () => _editar(context, lista, d),
                onEliminar: () => _eliminar(context, ref, d),
              ),
          if (!puedeAgregar && lista.length >= DireccionesService.maximo) ...[
            const SizedBox(height: 4),
            Text(
              DireccionesService.limite,
              style: textos.bodySmall
                  ?.copyWith(color: AppColors.textoSecundario),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ícono según el nombre: casa, trabajo u otro lugar.
IconData iconoDireccion(String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('casa') || n.contains('apart') || n.contains('hogar')) {
    return Icons.home_outlined;
  }
  if (n.contains('trabajo') || n.contains('oficina')) {
    return Icons.work_outline_rounded;
  }
  return Icons.place_outlined;
}

/// Una dirección guardada con sus botones de editar y eliminar.
class FilaDireccion extends StatelessWidget {
  const FilaDireccion({
    super.key,
    required this.direccion,
    required this.onEditar,
    required this.onEliminar,
  });

  final DireccionGuardada direccion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final d = direccion;
    final referencia = d.puntoReferencia?.trim() ?? '';
    final detalle = [
      if (d.zona != null) d.zona!,
      d.direccion,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.arena),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarioClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconoDireccion(d.nombre),
              size: 20,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nombre,
                  style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodySmall?.copyWith(color: AppColors.texto),
                ),
                if (referencia.isNotEmpty)
                  Text(
                    'Ref.: $referencia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.bodySmall
                        ?.copyWith(color: AppColors.textoSecundario),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar ${d.nombre}',
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Eliminar ${d.nombre}',
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
