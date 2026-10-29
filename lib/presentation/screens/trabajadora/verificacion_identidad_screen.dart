import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/archivo_foto.dart';
import '../../../domain/entities/mi_verificacion.dart';
import '../../../domain/services/verificacion_service.dart';
import '../../providers/sesion_provider.dart';
import '../../providers/verificaciones_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';
import 'barra_trabajadora.dart';

/// HU-21 · Verificar mi identidad (vista "verificacion" del Figma).
///
/// - c1: al enviar la cédula y la selfie, la verificación queda "En revisión".
/// - c2: aprobada → "Identidad verificada" (también en Mi perfil).
/// - c3: rechazada → se ve el motivo y se pueden subir fotos nuevas.
/// - c4: sin aprobar no se puede postular (PostulacionService, HU-12).
class VerificacionIdentidadScreen extends ConsumerStatefulWidget {
  const VerificacionIdentidadScreen({super.key});

  @override
  ConsumerState<VerificacionIdentidadScreen> createState() =>
      _VerificacionIdentidadScreenState();
}

class _VerificacionIdentidadScreenState
    extends ConsumerState<VerificacionIdentidadScreen> {
  ArchivoFoto? _cedula;
  ArchivoFoto? _selfie;
  String? _error;
  bool _enviando = false;

  Future<void> _elegir({required bool esCedula}) async {
    final archivos = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    final archivo = archivos.isEmpty ? null : archivos.first;
    if (archivo == null) return;
    // En web (y escritorio) los bytes se leen a demanda.
    final bytes = await archivo.readAsBytes();
    final foto = ArchivoFoto(bytes: bytes, nombre: archivo.name);

    final error = VerificacionService.validarFoto(foto);
    if (!mounted) return;
    setState(() {
      _error = error;
      if (error != null) return;
      if (esCedula) {
        _cedula = foto;
      } else {
        _selfie = foto;
      }
    });
  }

  Future<void> _enviar() async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(verificacionServiceProvider)
          .enviar(cedula: _cedula, selfie: _selfie);
      _cedula = null;
      _selfie = null;
      // La insignia del banner y del perfil leen la sesión.
      ref.invalidate(miVerificacionProvider);
      ref.invalidate(sesionProvider);
      mensajes.showSnackBar(
        const SnackBar(content: Text('Recibimos tus documentos.')),
      );
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final verificacion = ref.watch(miVerificacionProvider);
    final textos = Theme.of(context).textTheme;
    final movil = Responsive.esMovil(context);

    final contenido = verificacion.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EstadoVacio(
        icono: Icons.wifi_off_rounded,
        titulo: error is AppException
            ? error.mensaje
            : 'No pudimos cargar tu verificación.',
        textoBoton: 'Reintentar',
        onPressed: () => ref.invalidate(miVerificacionProvider),
      ),
      data: (actual) => switch (actual?.estado) {
        EstadoVerificacion.aprobada => const _Resultado(
            key: Key('verificacion-aprobada'),
            insignia: InsigniaEstado('Aprobada', tono: TonoInsignia.verde),
            icono: Icons.verified_user_outlined,
            titulo: 'Tu identidad está verificada',
            mensaje: 'Ya puedes postularte a las solicitudes de tus zonas.',
            textoBoton: 'Ver trabajos',
            ruta: Rutas.inicioTrabajadora,
          ),
        EstadoVerificacion.enRevision => const _Resultado(
            key: Key('verificacion-en-revision'),
            insignia: InsigniaEstado('En revisión', tono: TonoInsignia.azul),
            icono: Icons.shield_outlined,
            titulo: 'Recibimos tus documentos',
            mensaje: 'Te avisaremos cuando termine la revisión. Mientras '
                'tanto puedes completar tu perfil.',
            textoBoton: 'Ir a mi perfil',
            ruta: Rutas.perfilTrabajadora,
          ),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (actual?.estado == EstadoVerificacion.rechazada) ...[
                _AvisoRechazo(motivo: actual?.motivoRechazo),
                const SizedBox(height: 16),
              ],
              const _AvisoPrivacidad(),
              const SizedBox(height: 24),
              _Formulario(
                cedula: _cedula,
                selfie: _selfie,
                error: _error,
                enviando: _enviando,
                movil: movil,
                onElegirCedula: () => _elegir(esCedula: true),
                onElegirSelfie: () => _elegir(esCedula: false),
                onEnviar: _enviar,
              ),
            ],
          ),
      },
    );

    return Scaffold(
      body: Column(
        children: [
          BarraTrabajadora(
            nombre: sesion?.nombre ?? '',
            fotoUrl: sesion?.fotoUrl,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                anchoMaximo: 980,
                vertical: movil ? 32 : 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SEGURIDAD LIMPIAYA',
                      style: textos.labelSmall?.copyWith(
                        color: AppColors.primario,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verifica tu identidad',
                      style: movil ? textos.headlineLarge : textos.displayMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Esto protege a toda la comunidad y solo toma unos '
                      'minutos.',
                      style: textos.bodyLarge,
                    ),
                    const SizedBox(height: 40),
                    contenido,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tus documentos son privados." (noticeBanner del Figma).
class _AvisoPrivacidad extends StatelessWidget {
  const _AvisoPrivacidad();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primarioClaro,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: AppColors.primario),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus documentos son privados.',
                  style: textos.titleSmall?.copyWith(color: AppColors.primario),
                ),
                Text(
                  'Solo el equipo administrador puede revisarlos. Nunca se '
                  'muestran a clientes.',
                  style: textos.bodySmall?.copyWith(color: AppColors.primario),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// HU-21 c3 · El administrador rechazó la verificación: se muestra el motivo.
class _AvisoRechazo extends StatelessWidget {
  const _AvisoRechazo({required this.motivo});

  final String? motivo;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      key: const Key('aviso-rechazo'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.insigniaRojaFondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_bad_outlined, color: AppColors.error),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu verificación fue rechazada',
                  style: textos.titleSmall?.copyWith(color: AppColors.error),
                ),
                if (motivo != null && motivo!.trim().isNotEmpty)
                  Text('Motivo: $motivo', style: textos.bodyMedium),
                Text(
                  'Sube fotos nuevas y envíalas otra vez.',
                  style: textos.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Las dos cajas para subir fotos y el botón "Enviar a revisión".
class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.cedula,
    required this.selfie,
    required this.error,
    required this.enviando,
    required this.movil,
    required this.onElegirCedula,
    required this.onElegirSelfie,
    required this.onEnviar,
  });

  final ArchivoFoto? cedula;
  final ArchivoFoto? selfie;
  final String? error;
  final bool enviando;
  final bool movil;
  final VoidCallback onElegirCedula;
  final VoidCallback onElegirSelfie;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cajas = [
      _CajaSubida(
        key: const Key('subir-cedula'),
        titulo: 'Foto de tu cédula',
        ayuda: 'Que se vea completa y legible',
        foto: cedula,
        habilitada: !enviando,
        onTap: onElegirCedula,
      ),
      _CajaSubida(
        key: const Key('subir-selfie'),
        titulo: 'Selfie sosteniendo tu cédula',
        ayuda: 'Tu rostro y documento deben verse claros',
        foto: selfie,
        habilitada: !enviando,
        onTap: onElegirSelfie,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(movil ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (movil)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [cajas[0], const SizedBox(height: 16), cajas[1]],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cajas[0]),
                const SizedBox(width: 20),
                Expanded(child: cajas[1]),
              ],
            ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              error!,
              style: textos.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: enviando ? null : onEnviar,
            child: enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar a revisión'),
          ),
        ],
      ),
    );
  }
}

/// Caja punteada del Figma ("uploadBox"). Con foto elegida muestra la vista
/// previa y permite cambiarla.
class _CajaSubida extends StatelessWidget {
  const _CajaSubida({
    super.key,
    required this.titulo,
    required this.ayuda,
    required this.foto,
    required this.habilitada,
    required this.onTap,
  });

  final String titulo;
  final String ayuda;
  final ArchivoFoto? foto;
  final bool habilitada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final elegida = foto != null;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: elegida ? AppColors.primario : AppColors.borde,
        width: 2,
      ),
    );

    return Material(
      color: AppColors.fondo,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: habilitada ? onTap : null,
        child: SizedBox(
          height: 180,
          child: elegida
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      Uint8List.fromList(foto!.bytes),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, pila) => const Center(
                        child: Icon(Icons.image_outlined, size: 32),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.superficie.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: AppColors.exito,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                titulo,
                                style: textos.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Cambiar',
                              style: textos.labelSmall
                                  ?.copyWith(color: AppColors.primario),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_rounded,
                        color: AppColors.primario,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        titulo,
                        style: textos.titleSmall
                            ?.copyWith(color: AppColors.primario),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ayuda,
                        style: textos.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Tarjeta de resultado ("successState" del Figma): en revisión o aprobada.
class _Resultado extends StatelessWidget {
  const _Resultado({
    super.key,
    required this.insignia,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    required this.textoBoton,
    required this.ruta,
  });

  final Widget insignia;
  final IconData icono;
  final String titulo;
  final String mensaje;
  final String textoBoton;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
      ),
      child: Column(
        children: [
          insignia,
          const SizedBox(height: 20),
          Icon(icono, size: 56, color: AppColors.primario),
          const SizedBox(height: 20),
          Text(titulo, style: textos.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(mensaje, style: textos.bodyMedium?.copyWith(
              color: AppColors.textoSecundario,
            ), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go(ruta),
            child: Text(textoBoton),
          ),
        ],
      ),
    );
  }
}
