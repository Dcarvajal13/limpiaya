import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/cuenta_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';

/// HU-42 · Desactivar mi cuenta.
///
/// Criterios de aceptación:
/// 1. Sin servicios asignados pendientes, al confirmar, el perfil deja de
///    verse y se cierra la sesión.
/// 2. Con servicios asignados pendientes, se explica que primero debe
///    completarlos o cancelarlos.
/// 3. Una reseña de una cuenta desactivada se muestra como "Usuario inactivo"
///    (lo resuelve la vista `resenas_publicas`).
class DesactivarCuentaScreen extends ConsumerStatefulWidget {
  const DesactivarCuentaScreen({super.key});

  @override
  ConsumerState<DesactivarCuentaScreen> createState() =>
      _DesactivarCuentaScreenState();
}

class _DesactivarCuentaScreenState
    extends ConsumerState<DesactivarCuentaScreen> {
  bool _desactivando = false;
  String? _error;

  Future<void> _pedirConfirmacion() async {
    setState(() => _error = null);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Desactivar tu cuenta?'),
        content: const Text(
          'Tu perfil dejará de verse y se cerrará tu sesión. Si tienes '
          'servicios asignados sin completar, primero deberás completarlos '
          'o cancelarlos.',
        ),
        actions: [
          TextButton(
            key: const Key('cancelar-desactivar'),
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const Key('confirmar-desactivar'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Sí, desactivar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await _desactivar();
  }

  Future<void> _desactivar() async {
    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _desactivando = true);
    final error = await ref.read(cuentaProvider.notifier).desactivar();
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _desactivando = false;
        _error = error;
      });
      return;
    }

    // Criterio 1: al quedar inactiva, se cierra la sesión.
    await ref.read(authRepositoryProvider).cerrarSesion();
    if (!mounted) return;
    setState(() => _desactivando = false);

    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Tu cuenta quedó desactivada')),
      );
    router.go(Rutas.login);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Desactivar mi cuenta')),
      body: DesplazableConPie(
        child: ContenidoCentrado(
          vertical: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dejar de usar LimpiaYa',
                      style: textos.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tu cuenta no se borra: se desactiva. Esto es lo que pasa:',
                style: textos.bodyMedium,
              ),
              const SizedBox(height: 16),
              const _Punto(
                'Tu perfil deja de aparecer en búsquedas y perfiles públicos.',
              ),
              const _Punto(
                'Se cancelan las solicitudes que tengas publicadas y se '
                'retiran tus postulaciones pendientes.',
              ),
              const _Punto('Se cierra tu sesión en este dispositivo.'),
              const _Punto(
                'Tus reseñas siguen visibles, pero aparecen como '
                '“Usuario inactivo”.',
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borde),
                ),
                child: Text(
                  'Si tienes un servicio asignado sin completar, no podrás '
                  'desactivar la cuenta: primero complétalo o cancélalo.',
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textoSecundario,
                    height: 1.4,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: textos.bodySmall?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('desactivar-cuenta'),
                onPressed: _desactivando ? null : _pedirConfirmacion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _desactivando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Desactivar mi cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.circle,
            size: 6,
            color: AppColors.textoSecundario,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
