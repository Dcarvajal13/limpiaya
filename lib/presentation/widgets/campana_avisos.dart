import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/rutas.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/services/aviso_service.dart';
import '../providers/avisos_provider.dart';

/// HU-50 · Campana de avisos en la barra superior con contador de no leídos.
///
/// Si se renderiza fuera de un `ProviderScope` (pruebas aisladas de la barra),
/// muestra el ícono sin contador en vez de fallar.
class CampanaAvisos extends StatelessWidget {
  const CampanaAvisos({super.key, this.noLeidosManual});

  /// Permite inyectar el contador en pruebas de widgets aisladas.
  final int? noLeidosManual;

  @override
  Widget build(BuildContext context) {
    if (noLeidosManual != null) {
      return _BotonCampana(cantidad: noLeidosManual!);
    }
    final tieneProviderScope =
        context.findAncestorWidgetOfExactType<UncontrolledProviderScope>() !=
            null;
    if (!tieneProviderScope) {
      return const _BotonCampana(cantidad: 0);
    }
    return const _CampanaReactiva();
  }
}

class _CampanaReactiva extends ConsumerWidget {
  const _CampanaReactiva();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cantidad = ref.watch(avisosNoLeidosProvider);
    return _BotonCampana(cantidad: cantidad);
  }
}

class _BotonCampana extends StatelessWidget {
  const _BotonCampana({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final etiqueta = AvisoService.etiquetaContador(cantidad);
    final tooltip = cantidad > 0
        ? 'Avisos ($cantidad sin leer)'
        : 'Avisos';

    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        key: const Key('campana-avisos'),
        tooltip: tooltip,
        onPressed: () {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            router.push(Rutas.avisos);
          }
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              cantidad > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
              color: AppColors.texto,
              size: 24,
            ),
            if (etiqueta.isNotEmpty)
              Positioned(
                right: -6,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: AppColors.acentoTexto,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    etiqueta,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
