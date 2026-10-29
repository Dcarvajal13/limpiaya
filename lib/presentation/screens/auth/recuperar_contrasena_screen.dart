import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../widgets/campo_texto.dart';
import 'login_screen.dart';
import 'widgets/plantilla_auth.dart';

/// HU-19 · "¿Olvidaste tu contraseña?" (taller UX: H3 y H9, severidad 3).
///
/// Pide el correo y envía el enlace. Siempre muestra el mismo mensaje de
/// éxito, exista o no la cuenta, para no revelar qué correos están
/// registrados.
class RecuperarContrasenaScreen extends ConsumerStatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  ConsumerState<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState
    extends ConsumerState<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _cargando = false;
  bool _enviado = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .enviarRecuperacion(_email.text.trim().toLowerCase());
      if (mounted) setState(() => _enviado = true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    final volver = TextButton.icon(
      onPressed: () => context.go(Rutas.login),
      icon: const Icon(Icons.arrow_back_rounded, size: 20),
      label: const Text('Volver a iniciar sesión'),
    );

    final Widget contenido;
    if (_enviado) {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: AppColors.primario,
          ),
          const SizedBox(height: 16),
          Text('Revisa tu correo', style: textos.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Si ${_email.text.trim()} tiene una cuenta, te enviamos un enlace '
            'para crear una contraseña nueva. Ábrelo en este mismo navegador.',
            style: textos.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '¿No llegó? Revisa la carpeta de spam o vuelve a intentarlo en un '
            'minuto.',
            style: textos.bodySmall,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => setState(() => _enviado = false),
            child: const Text('Usar otro correo'),
          ),
          const SizedBox(height: 8),
          volver,
        ],
      );
    } else {
      contenido = Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Olvidaste tu contraseña?', style: textos.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Escribe el correo de tu cuenta y te enviaremos un enlace para '
              'crear una nueva.',
              style: textos.bodyLarge,
            ),
            const SizedBox(height: 28),
            CampoTexto(
              etiqueta: 'Correo',
              pista: 'nombre@correo.com',
              controller: _email,
              validator: Validadores.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _enviar(),
              enabled: !_cargando,
            ),
            if (_error != null) ...[
              const SizedBox(height: 18),
              AvisoErrorAuth(_error!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _cargando ? null : _enviar,
              child: _cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Enviarme el enlace'),
            ),
            const SizedBox(height: 8),
            volver,
          ],
        ),
      );
    }

    return PlantillaAuth(
      titulo: 'Recupera el acceso a tu cuenta.',
      texto: 'Te enviaremos un enlace seguro a tu correo. Nunca te pediremos '
          'tu contraseña por mensaje.',
      child: contenido,
    );
  }
}
