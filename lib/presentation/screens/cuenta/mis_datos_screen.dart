import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/mascara_telefono.dart';
import '../../../core/utils/validadores.dart';
import '../../providers/cuenta_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';

/// HU-41 · Editar mis datos personales.
///
/// Criterios de aceptación:
/// 1. Se ven el nombre y el teléfono actuales de la cuenta.
/// 2. Se pueden guardar un nombre y un teléfono válidos; el nombre nuevo se
///    refleja en toda la app.
/// 3. El teléfono conserva el formato venezolano 04XX-XXXXXXX.
class MisDatosScreen extends ConsumerStatefulWidget {
  const MisDatosScreen({super.key});

  @override
  ConsumerState<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends ConsumerState<MisDatosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String? _errorCarga;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final datos = await ref.read(cuentaRepositoryProvider).datosPersonales();
      if (!mounted) return;
      setState(() {
        _nombre.text = datos.nombre;
        _telefono.text = datos.telefono;
        _cargando = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCarga = e.mensaje;
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final router = GoRouter.of(context);
    final mensajes = ScaffoldMessenger.of(context);

    setState(() => _guardando = true);
    final error = await ref
        .read(cuentaProvider.notifier)
        .actualizarDatos(nombre: _nombre.text, telefono: _telefono.text);
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    ref.invalidate(sesionProvider);
    mensajes
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Datos actualizados')));
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Rutas.inicio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: DesplazableConPie(
        child: ContenidoCentrado(
          vertical: 32,
          child: _cargando
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorCarga != null
              ? _ErrorCarga(mensaje: _errorCarga!, onReintentar: _cargar)
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tus datos', style: textos.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Tu nombre aparece en la app. Tu teléfono es '
                        'privado y no se comparte con la otra parte.',
                        style: textos.bodySmall?.copyWith(
                          color: AppColors.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CampoTexto(
                        etiqueta: 'Nombre y apellido',
                        pista: 'Valentina Rojas',
                        controller: _nombre,
                        validator: Validadores.requerido,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        enabled: !_guardando,
                      ),
                      const SizedBox(height: 18),
                      CampoTexto(
                        etiqueta: 'Teléfono',
                        pista: '0414-1234567',
                        ayuda: 'Formato: 0414-1234567',
                        controller: _telefono,
                        validator: Validadores.telefono,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: const [MascaraTelefono()],
                        onFieldSubmitted: (_) => _guardar(),
                        enabled: !_guardando,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          _error!,
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const Key('guardar-datos'),
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 32),
        Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.error),
        const SizedBox(height: 12),
        Text(mensaje, textAlign: TextAlign.center, style: textos.bodyMedium),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onReintentar,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
