import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../providers/cuenta_provider.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';

/// HU-39 · Cambiar mi contraseña desde mi cuenta.
///
/// Criterios de aceptación:
/// 1. Con la contraseña actual correcta y una nueva de al menos 8 caracteres,
///    se actualiza y se ve una confirmación.
/// 2. Si la actual es incorrecta, se ve el error y no se cambia.
/// 3. Si la nueva y su confirmación no coinciden, se ve
///    "Las contraseñas no coinciden".
class CambiarContrasenaScreen extends ConsumerStatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  ConsumerState<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState
    extends ConsumerState<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetir = TextEditingController();

  bool _ver = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetir.dispose();
    super.dispose();
  }

  String? _validarRepeticion(String? valor) {
    if (valor != _nueva.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _guardando = true);
    final error = await ref.read(cuentaProvider.notifier).cambiarContrasena(
          actual: _actual.text,
          nueva: _nueva.text,
        );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Rutas.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ojo = IconButton(
      tooltip: _ver ? 'Ocultar contraseñas' : 'Mostrar contraseñas',
      icon: Icon(
        _ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: () => setState(() => _ver = !_ver),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: DesplazableConPie(
        child: ContenidoCentrado(
          vertical: 32,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tu contraseña', style: textos.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Para cambiarla necesitamos la que usas ahora. Si no la '
                  'recuerdas, cierra sesión y usa “¿Olvidaste tu contraseña?”.',
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                ),
                const SizedBox(height: 24),
                CampoTexto(
                  etiqueta: 'Contraseña actual',
                  controller: _actual,
                  validator: Validadores.requerido,
                  obscureText: !_ver,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  enabled: !_guardando,
                ),
                const SizedBox(height: 18),
                CampoTexto(
                  etiqueta: 'Contraseña nueva',
                  pista: 'Mínimo ${AppConstants.largoMinimoPassword} caracteres',
                  ayuda: 'Mínimo ${AppConstants.largoMinimoPassword} caracteres',
                  controller: _nueva,
                  validator: Validadores.password,
                  obscureText: !_ver,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  enabled: !_guardando,
                  sufijo: ojo,
                ),
                const SizedBox(height: 18),
                CampoTexto(
                  etiqueta: 'Repite la contraseña nueva',
                  controller: _repetir,
                  validator: _validarRepeticion,
                  obscureText: !_ver,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _guardar(),
                  enabled: !_guardando,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _error!,
                    style: textos.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('guardar-contrasena'),
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Guardar contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
