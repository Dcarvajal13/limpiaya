import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../widgets/campo_texto.dart';
import 'widgets/plantilla_auth.dart';

/// HU-02A / HU-02B · Iniciar sesión (cliente y trabajadora).
///
/// Es la misma pantalla para los dos roles. Al entrar, el router lee el rol
/// y manda a cada quien a su inicio (core/router/redireccion.dart):
/// - cliente → Mis solicitudes
/// - trabajadora → Solicitudes disponibles
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _verPassword = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    // Cada intento empieza sin el error del intento anterior.
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ref.read(authRepositoryProvider).iniciarSesion(
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
          );
      // Listo: el router se encarga de llevarlo a su inicio.
    } on AppException catch (e) {
      _mostrarError(e.mensaje);
    } catch (_) {
      _mostrarError('No pudimos iniciar sesión. Intenta de nuevo.');
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _error = mensaje;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return PlantillaAuth(
      titulo: 'Qué bueno verte por aquí.',
      texto: 'Tus solicitudes, mensajes y reseñas siguen esperándote.',
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hola de nuevo', style: textos.headlineLarge),
              const SizedBox(height: 8),
              Text('Entra con tus datos.', style: textos.bodyLarge),
              const SizedBox(height: 28),
              CampoTexto(
                etiqueta: 'Correo',
                pista: 'tu@correo.com',
                controller: _email,
                validator: Validadores.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                enabled: !_cargando,
              ),
              const SizedBox(height: 18),
              CampoTexto(
                etiqueta: 'Contraseña',
                pista: 'Tu contraseña',
                controller: _password,
                validator: Validadores.requerido,
                obscureText: !_verPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                enabled: !_cargando,
                sufijo: IconButton(
                  tooltip: _verPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  icon: Icon(
                    _verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                _AvisoError(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _entrar,
                child: _cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('¿Aún no tienes cuenta?', style: textos.bodySmall),
                  TextButton(
                    onPressed: () => context.go(Rutas.registro),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje de error del inicio de sesión (fondo rojo claro, texto rojo).
class _AvisoError extends StatelessWidget {
  const _AvisoError(this.mensaje);

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.insigniaRojaFondo,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
