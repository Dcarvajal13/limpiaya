import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/utils/validadores.dart';
import '../../providers/recuperacion_provider.dart';
import '../../widgets/campo_texto.dart';
import 'login_screen.dart';
import 'widgets/plantilla_auth.dart';

/// HU-19 · Crear una contraseña nueva. Se llega desde el enlace del correo,
/// que ya deja la sesión abierta.
class NuevaContrasenaScreen extends ConsumerStatefulWidget {
  const NuevaContrasenaScreen({super.key});

  @override
  ConsumerState<NuevaContrasenaScreen> createState() =>
      _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState extends ConsumerState<NuevaContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();

  bool _verPassword = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  String? _validarConfirmacion(String? valor) {
    if (valor != _password.text) return 'Las contraseñas no coinciden';
    return null;
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _cargando = true);
    try {
      await ref.read(authRepositoryProvider).cambiarPassword(_password.text);
      ref.read(recuperandoContrasenaProvider.notifier).terminar();
      mensajes.showSnackBar(
        const SnackBar(content: Text('Listo, guardamos tu contraseña nueva.')),
      );
      router.go(Rutas.inicio);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ojo = IconButton(
      tooltip: _verPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
      icon: Icon(
        _verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: () => setState(() => _verPassword = !_verPassword),
    );

    return PlantillaAuth(
      titulo: 'Un nuevo comienzo.',
      texto: 'Elige una contraseña que no uses en otras páginas.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Crea tu contraseña nueva', style: textos.headlineLarge),
              const SizedBox(height: 28),
              CampoTexto(
                etiqueta: 'Contraseña nueva',
                pista: 'Mínimo ${AppConstants.largoMinimoPassword} caracteres',
                ayuda: 'Mínimo ${AppConstants.largoMinimoPassword} caracteres',
                controller: _password,
                validator: Validadores.password,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_cargando,
                sufijo: ojo,
              ),
              const SizedBox(height: 18),
              CampoTexto(
                etiqueta: 'Repite la contraseña',
                controller: _confirmacion,
                validator: _validarConfirmacion,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _guardar(),
                enabled: !_cargando,
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                AvisoErrorAuth(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _guardar,
                child: _cargando
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
    );
  }
}
