import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../../domain/entities/perfil_cliente.dart';
import '../../providers/perfil_cliente_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/seccion_cuenta.dart';
import '../../widgets/selector_zona.dart';
import 'barra_cliente.dart';

/// HU-05 · Crear mi perfil de cliente.
///
/// Criterios de aceptación:
/// 1. Sin zona ni dirección, al publicar una solicitud se pide completarlas
///    antes (la redirección está en core/router/redireccion.dart; el alta
///    de solicitudes, HU-07, usará estos datos).
/// 2. Con el perfil completo, al crear una solicitud la zona y la dirección
///    aparecen precargadas y se pueden cambiar (los datos quedan en la
///    tabla `clientes` para que HU-07 los lea).
/// 3. La dirección exacta es privada: las trabajadoras ven solo la zona
///    (vista `solicitudes_publicas`, HD-03).
class PerfilClienteScreen extends ConsumerStatefulWidget {
  const PerfilClienteScreen({super.key});

  @override
  ConsumerState<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends ConsumerState<PerfilClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _punto = TextEditingController();

  int? _zonaElegida;
  bool _sembrado = false;
  bool _guardando = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _direccion.dispose();
    _punto.dispose();
    super.dispose();
  }

  void _sembrar(PerfilCliente? perfil) {
    if (perfil == null || _sembrado) return;
    _sembrado = true;
    _direccion.text = perfil.direccion ?? '';
    _punto.text = perfil.puntoReferencia ?? '';
    _zonaElegida = perfil.zona?.id;
  }

  Future<void> _guardar() async {
    setState(() => _errorGeneral = null);
    if (_zonaElegida == null) {
      setState(() => _errorGeneral = 'Elige tu zona');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    final ok = await ref.read(perfilClienteProvider.notifier).guardar(
          zonaId: _zonaElegida!,
          direccion: _direccion.text,
          puntoReferencia:
              _punto.text.trim().isEmpty ? null : _punto.text.trim(),
        );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Perfil guardado')));
      // Vuelve a Mis solicitudes: ya no hay motivo para quedarse acá.
      context.go(Rutas.inicioCliente);
    } else {
      final error = ref.read(perfilClienteProvider).error;
      setState(() => _errorGeneral = error is AppException
          ? error.mensaje
          : 'No pudimos guardar tu perfil. Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';
    final perfil = ref.watch(perfilClienteProvider);
    final zonasAsync = ref.watch(zonasClienteProvider);

    ref.listen(perfilClienteProvider, (_, next) {
      if (next.value != null && !_sembrado) {
        _sembrar(next.value);
        setState(() {});
      }
    });
    _sembrar(perfil.value);

    final textos = Theme.of(context).textTheme;
    final textoError =
        textos.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error);

    final sesion = ref.watch(sesionProvider).value;

    // Corrección de la revisión: misma barra que el resto de pantallas del
    // cliente; "Cerrar sesión" está al final del perfil.
    return Scaffold(
      body: Column(
        children: [
          BarraCliente(
            nombre: sesion?.nombre ?? nombre,
            fotoUrl: sesion?.fotoUrl,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: 32,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Completa tu perfil', style: textos.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Hola, $nombre. Necesitamos tu zona y dirección para '
                        'que puedas publicar solicitudes.',
                        style: textos.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      if (perfil.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else ...[
                        Text('¿En qué zona estás?', style: textos.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Elige el municipio, luego la parroquia y por último '
                          'tu urbanización.',
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (zonasAsync.hasError)
                          Text(
                            'No pudimos cargar las zonas. Recarga la página.',
                            style: textoError,
                          )
                        else if (zonasAsync.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          // Corrección de la revisión: Municipio →
                          // Parroquia → Urbanización.
                          SelectorZona(
                            zonas: zonasAsync.value ?? const [],
                            valor: _zonaElegida,
                            onChanged: (valor) => setState(() {
                              _zonaElegida = valor;
                              _errorGeneral = null;
                            }),
                            validator: (_) =>
                                _zonaElegida == null ? 'Elige tu zona' : null,
                          ),
                        const SizedBox(height: 20),
                        CampoTexto(
                          etiqueta: 'Dirección',
                          pista: 'Av. Francisco de Miranda, Edificio…',
                          controller: _direccion,
                          validator: Validadores.direccion,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solo la ve la trabajadora que elijas.',
                          style: textos.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        CampoTexto(
                          etiqueta: 'Punto de referencia (opcional)',
                          pista: 'Al lado del farmatodo',
                          controller: _punto,
                          validator: Validadores.maximo(200),
                        ),
                        const SizedBox(height: 24),
                        if (_errorGeneral != null) ...[
                          Text(_errorGeneral!, style: textoError),
                          const SizedBox(height: 12),
                        ],
                        FilledButton(
                          onPressed: _guardando ? null : _guardar,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Puedes cambiarlos cuando quieras.',
                            style: textos.bodySmall?.copyWith(
                              color: AppColors.textoSecundario,
                            ),
                          ),
                        ),
                        const SeccionCuenta(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
