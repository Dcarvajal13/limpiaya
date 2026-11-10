import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/utils/mascara_telefono.dart';
import '../../../core/utils/validadores.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../providers/registro_provider.dart';

/// HU-01 · Registrarme eligiendo mi rol.
class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();

  RolUsuario? _rol;
  bool _aceptoTerminos = false;
  bool _verPassword = false;
  bool _intentoEnviar = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _telefono.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _intentoEnviar = true);
    final formularioOk = _formKey.currentState!.validate();
    if (!formularioOk || _rol == null || !_aceptoTerminos) return;

    final ok = await ref.read(registroControllerProvider.notifier).registrar(
          nombre: _nombre.text,
          email: _email.text,
          telefono: _telefono.text,
          password: _password.text,
          rol: _rol,
          aceptoTerminos: _aceptoTerminos,
        );
    if (!mounted || !ok) return;

    // Con sesión activa, el router lleva solo al inicio (HU-01 c1).
    // Sin sesión, Supabase está pidiendo confirmar el correo.
    if (ref.read(authRepositoryProvider).usuarioActual == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Revisa tu correo'),
          content: const Text(
            'Te enviamos un enlace para confirmar tu cuenta. '
            'Después podrás iniciar sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.go(Rutas.login),
              child: const Text('Ir a iniciar sesión'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registroControllerProvider);
    final cargando = estado.isLoading;
    final error = estado.hasError ? _mensajeDeError(estado.error!) : null;

    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final textoError = tema.textTheme.bodySmall?.copyWith(color: colores.error);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                autovalidateMode: _intentoEnviar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crea tu cuenta',
                        style: tema.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Row(
                        children: [
                          const Text('¿Ya tienes cuenta?'),
                          TextButton(
                            onPressed: () => context.go(Rutas.login),
                            child: const Text('Inicia sesión'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('¿Qué buscas?', style: tema.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TarjetaRol(
                              icono: Icons.home_outlined,
                              titulo: 'Necesito limpieza',
                              descripcion: 'Publico y elijo',
                              seleccionada: _rol == RolUsuario.cliente,
                              onTap: () =>
                                  setState(() => _rol = RolUsuario.cliente),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TarjetaRol(
                              icono: Icons.person_outline,
                              titulo: 'Quiero trabajar',
                              descripcion: 'Me postulo cerca',
                              seleccionada: _rol == RolUsuario.trabajadora,
                              onTap: () =>
                                  setState(() => _rol = RolUsuario.trabajadora),
                            ),
                          ),
                        ],
                      ),
                      if (_intentoEnviar && _rol == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Elige una opción', style: textoError),
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nombre,
                        decoration:
                            const InputDecoration(labelText: 'Nombre completo'),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: Validadores.requerido,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Correo'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validadores.email,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _telefono,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          hintText: '04XX-XXXXXXX',
                          helperText: 'Escribe solo los números; el guion '
                              'se pone solo',
                        ),
                        keyboardType: TextInputType.phone,
                        // Taller UX, H5 (severidad 3): máscara automática.
                        inputFormatters: const [MascaraTelefono()],
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: Validadores.telefono,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: !_verPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText: 'Mínimo 8 caracteres',
                          suffixIcon: IconButton(
                            tooltip: _verPassword
                                ? 'Ocultar contraseña'
                                : 'Mostrar contraseña',
                            icon: Icon(_verPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _verPassword = !_verPassword),
                          ),
                        ),
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validadores.password,
                        onFieldSubmitted: (_) => _enviar(),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _aceptoTerminos,
                        onChanged: (v) =>
                            setState(() => _aceptoTerminos = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Acepto los Términos y condiciones, '
                          'incluida la tarifa de servicio.',
                        ),
                      ),
                      if (_intentoEnviar && !_aceptoTerminos)
                        Text(
                          'Debes aceptar los Términos y condiciones',
                          style: textoError,
                        ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colores.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            error,
                            style: TextStyle(color: colores.onErrorContainer),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: cargando ? null : _enviar,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _mensajeDeError(Object error) {
    if (error is AppException) return error.mensaje;
    return 'No pudimos crear tu cuenta. Intenta de nuevo.';
  }
}

/// Tarjeta para elegir el rol: cliente o trabajadora.
class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.seleccionada,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return Semantics(
      button: true,
      selected: seleccionada,
      child: Material(
        color: colores.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: seleccionada ? colores.primary : colores.outlineVariant,
                width: seleccionada ? 2 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: colores.primary),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(descripcion, style: tema.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}