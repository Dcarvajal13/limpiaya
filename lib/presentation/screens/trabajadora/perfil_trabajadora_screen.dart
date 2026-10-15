import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validadores.dart';
import '../../../domain/entities/perfil_trabajadora.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/contenido_centrado.dart';
import 'barra_trabajadora.dart';

/// HU-04 · Crear mi perfil de trabajadora.
///
/// Criterios de aceptación:
/// 1. La recién registrada completa el perfil antes de ver solicitudes
///    (la redirección está en `core/router/redireccion.dart`).
/// 2. Con al menos una zona y un servicio, lo guardado se ve en el perfil.
/// 3. Sin zonas no guarda: se ve "Elige al menos una zona".
/// 4. Foto de más de 5 MB o que no sea JPG/PNG: error y queda la anterior.
/// 5. La tarifa se muestra como "Desde $X por hora"; si está vacía, no aparece.
class PerfilTrabajadoraScreen extends ConsumerStatefulWidget {
  const PerfilTrabajadoraScreen({super.key});

  @override
  ConsumerState<PerfilTrabajadoraScreen> createState() =>
      _PerfilTrabajadoraScreenState();
}

class _PerfilTrabajadoraScreenState
    extends ConsumerState<PerfilTrabajadoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experiencia = TextEditingController();
  final _tarifa = TextEditingController();
  final _descripcion = TextEditingController();

  final _zonasElegidas = <int>{};
  final _serviciosElegidos = <TipoLimpieza>{};

  /// El formulario se llena una sola vez con lo que trae el perfil.
  bool _sembrado = false;
  bool _guardando = false;
  bool _subiendoFoto = false;

  /// Mensaje debajo de los chips: falta una zona/servicio (criterio 3).
  String? _errorSeleccion;
  String? _errorGeneral;

  @override
  void dispose() {
    _experiencia.dispose();
    _tarifa.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _cambiarFoto() async {
    final archivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    final archivo = archivos.isEmpty ? null : archivos.first;
    if (archivo == null) return;
    // En web (y escritorio) los bytes se leen a demanda.
    final bytes = await archivo.readAsBytes();

    setState(() => _subiendoFoto = true);
    final ok = await ref.read(perfilProvider.notifier).subirFoto(
          bytes: bytes,
          nombreArchivo: archivo.name,
        );
    if (!mounted) return;
    setState(() => _subiendoFoto = false);

    final error = ref.read(perfilProvider).error;
    final mensaje = ok
        ? 'Foto actualizada'
        : (error is AppException
            ? error.mensaje
            : 'No pudimos subir la foto. Intenta de nuevo.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _guardar() async {
    setState(() {
      _errorSeleccion = null;
      _errorGeneral = null;
    });

    // Criterio 3: sin zonas (o sin servicios) no se guarda.
    if (_zonasElegidas.isEmpty) {
      setState(() => _errorSeleccion = 'Elige al menos una zona');
      return;
    }
    if (_serviciosElegidos.isEmpty) {
      setState(() => _errorSeleccion = 'Elige al menos un servicio');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    final ok = await ref.read(perfilProvider.notifier).guardar(
          zonasIds: _zonasElegidas.toList(),
          servicios: _serviciosElegidos.toList(),
          experienciaAnios: int.tryParse(_experiencia.text.trim()),
          tarifaReferencia: double.tryParse(_tarifa.text.trim().replaceAll(',', '.')),
          descripcion:
              _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
        );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Perfil guardado')));
    } else {
      final error = ref.read(perfilProvider).error;
      setState(() => _errorGeneral = error is AppException
          ? error.mensaje
          : 'No pudimos guardar tu perfil. Intenta de nuevo.');
    }
  }

  void _sembrar(PerfilTrabajadora? perfil) {
    if (perfil == null || _sembrado) return;
    _sembrado = true;
    _experiencia.text = perfil.experienciaAnios?.toString() ?? '';
    _tarifa.text = perfil.tarifaReferencia?.toString() ?? '';
    _descripcion.text = perfil.descripcion ?? '';
    _zonasElegidas
      ..clear()
      ..addAll(perfil.zonas.map((z) => z.id));
    _serviciosElegidos
      ..clear()
      ..addAll(perfil.servicios);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';
    final fotoUrl = ref.watch(sesionProvider).value?.fotoUrl;
    final perfil = ref.watch(perfilProvider);
    final zonasAsync = ref.watch(zonasProvider);

    // Cuando llega el perfil de la base, se llena el formulario.
    ref.listen(perfilProvider, (_, next) {
      if (next.value != null && !_sembrado) {
        _sembrar(next.value);
        setState(() {});
      }
    });
    _sembrar(perfil.value);

    final textoError = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        );

    return Scaffold(
      body: Column(
        children: [
          BarraTrabajadora(nombre: nombre, fotoUrl: fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: 32,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mi perfil',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Así te ven los clientes cuando eligen.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      // ---- Foto ----
                      Row(
                        children: [
                          _FotoPerfil(
                            fotoUrl: perfil.value?.fotoUrl,
                            nombre: nombre,
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _subiendoFoto ? null : _cambiarFoto,
                            icon: const Icon(Icons.photo_camera_outlined, size: 20),
                            label: Text(_subiendoFoto ? 'Subiendo foto…' : 'Cambiar foto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPG o PNG, hasta 5 MB.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 28),

                      // ---- Zonas ----
                      Text('¿Dónde trabajas?',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      if (zonasAsync.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (zonasAsync.hasError)
                        Text(
                          'No pudimos cargar las zonas. Recarga la página.',
                          style: textoError,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final Zona zona in zonasAsync.value ?? const <Zona>[])
                              FilterChip(
                                label: Text(zona.nombre),
                                selected: _zonasElegidas.contains(zona.id),
                                onSelected: (elegida) => setState(() {
                                  if (elegida) {
                                    _zonasElegidas.add(zona.id);
                                  } else {
                                    _zonasElegidas.remove(zona.id);
                                  }
                                  _errorSeleccion = null;
                                }),
                              ),
                          ],
                        ),
                      if (_errorSeleccion != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorSeleccion!, style: textoError),
                      ],
                      const SizedBox(height: 28),

                      // ---- Servicios ----
                      Text('¿Qué servicios ofreces?',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final TipoLimpieza tipo in TipoLimpieza.values)
                            FilterChip(
                              label: Text(tipo.etiqueta),
                              selected: _serviciosElegidos.contains(tipo),
                              onSelected: (elegido) => setState(() {
                                if (elegido) {
                                  _serviciosElegidos.add(tipo);
                                } else {
                                  _serviciosElegidos.remove(tipo);
                                }
                                _errorSeleccion = null;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ---- Experiencia y tarifa ----
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              etiqueta: 'Años de experiencia',
                              pista: '3',
                              controller: _experiencia,
                              keyboardType: TextInputType.number,
                              validator: Validadores.anosExperiencia,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CampoTexto(
                              etiqueta: 'Tarifa por hora (opcional)',
                              pista: '\$5',
                              controller: _tarifa,
                              keyboardType: TextInputType.number,
                              validator: Validadores.tarifa,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Criterio 5: "Desde $X por hora" mientras se escribe.
                      AnimatedBuilder(
                        animation: _tarifa,
                        builder: (context, _) {
                          final texto = _tarifaActual();
                          return texto == null
                              ? const SizedBox.shrink()
                              : Text(
                                  texto,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppColors.primarioOscuro),
                                );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ---- Descripción ----
                      CampoTexto(
                        etiqueta: 'Sobre mí (opcional)',
                        controller: _descripcion,
                        pista: 'Cuánto llevas limpiando, qué equipos usas…',
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
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Guardar cambios'),
                      ),
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

  /// Texto de la tarifa mientras se escribe (criterio 5).
  String? _tarifaActual() {
    final texto = _tarifa.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    final numero = double.tryParse(texto);
    if (numero == null || numero <= 0) return null;
    final entera = numero == numero.roundToDouble();
    return 'Desde \$${entera ? numero.toInt() : numero} por hora';
  }
}

/// Foto de perfil: la imagen si hay, o un ícono con la inicial.
class _FotoPerfil extends StatelessWidget {
  const _FotoPerfil({required this.fotoUrl, required this.nombre});

  final String? fotoUrl;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl;
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.primarioClaro,
      foregroundImage: url == null ? null : NetworkImage(url),
      child: url == null ? AvatarUsuario(nombre: nombre, tamano: 44) : null,
    );
  }
}
