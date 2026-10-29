import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/verificacion_pendiente.dart';
import '../../../domain/services/verificacion_service.dart';
import '../../providers/verificaciones_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/boton_cerrar_sesion.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';
import '../../widgets/logo_limpiaya.dart';

/// HU-33 · Revisar verificaciones de identidad (vista "admin" del Figma).
///
/// - c1: lista de la más antigua a la más reciente, con fotos y datos.
/// - c2: "Aprobar identidad" marca a la trabajadora como verificada.
/// - c3: "Rechazar" sin motivo muestra "Indica el motivo".
/// - c4: solo el admin entra a /admin (core/router/redireccion.dart).
class AdminInicioScreen extends ConsumerStatefulWidget {
  const AdminInicioScreen({super.key});

  @override
  ConsumerState<AdminInicioScreen> createState() => _AdminInicioScreenState();
}

class _AdminInicioScreenState extends ConsumerState<AdminInicioScreen> {
  String? _seleccionada;
  bool _guardando = false;

  void _elegir(VerificacionPendiente verificacion) {
    if (_guardando) return;
    setState(() => _seleccionada = verificacion.id);
  }

  Future<void> _aprobar(VerificacionPendiente verificacion) async {
    final confirmado = await _confirmar(
      titulo: '¿Aprobar esta identidad?',
      mensaje: 'La trabajadora podrá postularse a solicitudes disponibles.',
    );
    if (!confirmado) return;
    await _guardar(
      () => ref.read(verificacionServiceProvider).aprobar(verificacion.id),
      'Identidad aprobada. ${verificacion.nombre} ya puede postularse.',
    );
  }

  /// Corrección del review: el motivo ya no está siempre en la tarjeta;
  /// "Rechazar" abre un pop-up para escribirlo (HU-33 c3 sigue igual: sin
  /// motivo muestra "Indica el motivo" y no rechaza).
  Future<void> _rechazar(VerificacionPendiente verificacion) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => _DialogoRechazo(nombre: verificacion.nombre),
    );
    if (motivo == null) return;
    await _guardar(
      () => ref
          .read(verificacionServiceProvider)
          .rechazar(verificacion.id, motivo),
      'Verificación rechazada.',
    );
  }

  Future<void> _guardar(Future<void> Function() accion, String exito) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    try {
      await accion();
      _seleccionada = null;
      ref.invalidate(verificacionesPendientesProvider);
      mensajes.showSnackBar(SnackBar(content: Text(exito)));
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<bool> _confirmar({
    required String titulo,
    required String mensaje,
    bool peligro = false,
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: peligro ? AppTheme.botonPeligro : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = ref.watch(verificacionesPendientesProvider);
    final cantidad = pendientes.value?.length ?? 0;
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;

    final contenido = pendientes.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EstadoVacio(
        icono: Icons.error_outline_rounded,
        titulo: 'No pudimos cargar las verificaciones',
        mensaje: error is AppException ? error.mensaje : null,
        textoBoton: 'Intentar de nuevo',
        onPressed: () => ref.invalidate(verificacionesPendientesProvider),
      ),
      data: (lista) => _panel(lista, movil),
    );

    final principal = SingleChildScrollView(
      padding: movil
          ? const EdgeInsets.fromLTRB(16, 30, 16, 80)
          : const EdgeInsets.all(50),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verificaciones pendientes',
                style: movil ? textos.headlineLarge : textos.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Revisa de la más antigua a la más reciente.',
                style: textos.bodyLarge,
              ),
              const SizedBox(height: 40),
              contenido,
              if (movil) ...[
                const SizedBox(height: 32),
                const Center(child: BotonCerrarSesion()),
              ],
            ],
          ),
        ),
      ),
    );

    if (movil) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primarioOscuro,
          foregroundColor: Colors.white,
          toolbarHeight: 68,
          titleSpacing: 16,
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: LogoLimpiaYa(sobreOscuro: true, subtitulo: 'Admin', tamano: 36),
          ),
          // Como en el Figma, en el teléfono la barra solo lleva el contador;
          // "Cerrar sesión" queda al final de la página.
          actions: [
            Center(
              child: _ItemVerificaciones(cantidad: cantidad, compacto: true),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: principal,
      );
    }

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BarraLateral(cantidad: cantidad),
          Expanded(child: principal),
        ],
      ),
    );
  }

  Widget _panel(List<VerificacionPendiente> lista, bool movil) {
    if (lista.isEmpty) {
      return const EstadoVacio(
        icono: Icons.verified_user_outlined,
        titulo: 'No hay verificaciones pendientes',
        mensaje: 'Cuando una trabajadora envíe su cédula y su selfie, '
            'aparecerá aquí.',
      );
    }

    final actual = lista.firstWhere(
      (v) => v.id == _seleccionada,
      orElse: () => lista.first,
    );

    final listado = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final verificacion in lista) ...[
          _FilaVerificacion(
            verificacion: verificacion,
            activa: verificacion.id == actual.id,
            onTap: () => _elegir(verificacion),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );

    final detalle = _DetalleVerificacion(
      verificacion: actual,
      guardando: _guardando,
      movil: movil,
      onAprobar: () => _aprobar(actual),
      onRechazar: () => _rechazar(actual),
    );

    if (movil) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [listado, const SizedBox(height: 12), detalle],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 340, child: listado),
        const SizedBox(width: 20),
        Expanded(child: detalle),
      ],
    );
  }
}

/// Barra lateral oscura del Figma (solo escritorio).
class _BarraLateral extends StatelessWidget {
  const _BarraLateral({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.primarioOscuro,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: LogoLimpiaYa(sobreOscuro: true, subtitulo: 'Admin'),
          ),
          const SizedBox(height: 50),
          _ItemVerificaciones(cantidad: cantidad),
          const Spacer(),
          const Align(
            alignment: Alignment.centerLeft,
            child: _CerrarSesionSobreOscuro(),
          ),
        ],
      ),
    );
  }
}

/// "Verificaciones" con el número de pendientes (pastilla terracota).
class _ItemVerificaciones extends StatelessWidget {
  const _ItemVerificaciones({required this.cantidad, this.compacto = false});

  final int cantidad;

  /// En la barra del teléfono solo se ve el ícono y el número.
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final contador = cantidad == 0
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.acentoTexto, // texto blanco encima (WCAG)
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$cantidad',
              style: textos.labelSmall?.copyWith(color: Colors.white),
            ),
          );

    return Semantics(
      label: 'Verificaciones pendientes: $cantidad',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: compacto ? MainAxisSize.min : MainAxisSize.max,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            if (!compacto) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verificaciones',
                  style: textos.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ],
            if (contador != null) ...[const SizedBox(width: 6), contador],
          ],
        ),
      ),
    );
  }
}

/// El botón de cerrar sesión de siempre, con texto claro sobre el fondo oscuro.
class _CerrarSesionSobreOscuro extends StatelessWidget {
  const _CerrarSesionSobreOscuro();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textButtonTheme.style ?? const ButtonStyle();
    return TextButtonTheme(
      data: TextButtonThemeData(
        style: estilo.copyWith(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textoSobreOscuro),
        ),
      ),
      child: const BotonCerrarSesion(),
    );
  }
}

/// Una fila de la cola: avatar, nombre y cuándo la envió.
class _FilaVerificacion extends StatelessWidget {
  const _FilaVerificacion({
    required this.verificacion,
    required this.activa,
    required this.onTap,
  });

  final VerificacionPendiente verificacion;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: activa ? AppColors.primario : AppColors.borde,
        width: activa ? 2 : 1,
      ),
    );

    return Material(
      color: AppColors.superficie,
      shape: forma,
      child: InkWell(
        customBorder: forma,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarUsuario(
                nombre: verificacion.nombre,
                fotoUrl: verificacion.fotoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(verificacion.nombre, style: textos.titleMedium),
                    Text(
                      'Enviada ${Formato.fechaHoraCorta(verificacion.enviada)}',
                      style: textos.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textoSecundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con los datos, las dos fotos y los botones (centrados).
class _DetalleVerificacion extends StatelessWidget {
  const _DetalleVerificacion({
    required this.verificacion,
    required this.guardando,
    required this.movil,
    required this.onAprobar,
    required this.onRechazar,
  });

  final VerificacionPendiente verificacion;
  final bool guardando;
  final bool movil;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    final documentos = [
      _Documento(url: verificacion.cedulaUrl, etiqueta: 'Foto de la cédula'),
      _Documento(
        url: verificacion.selfieUrl,
        etiqueta: 'Selfie sosteniendo la cédula',
      ),
    ];

    final rechazar = FilledButton(
      style: AppTheme.botonPeligro,
      onPressed: guardando ? null : onRechazar,
      child: const Text('Rechazar'),
    );
    final aprobar = FilledButton(
      onPressed: guardando ? null : onAprobar,
      child: guardando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Aprobar identidad'),
    );

    return Container(
      padding: EdgeInsets.all(movil ? 24 : 32),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        border: Border.all(color: AppColors.borde),
        borderRadius: BorderRadius.circular(AppTheme.radioTarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AvatarUsuario(
                nombre: verificacion.nombre,
                fotoUrl: verificacion.fotoUrl,
                tamano: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verificacion.nombre,
                      style: movil ? textos.headlineMedium : textos.headlineLarge,
                    ),
                    const SizedBox(height: 7),
                    const InsigniaEstado('En revisión', tono: TonoInsignia.azul),
                    const SizedBox(height: 7),
                    Text(
                      'Cuenta creada el '
                      '${Formato.fechaConAnio(verificacion.cuentaCreada)}',
                      style: textos.bodySmall,
                    ),
                    if (verificacion.telefono != null)
                      Text(
                        'Teléfono: ${verificacion.telefono}',
                        style: textos.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Documentos enviados', style: textos.titleLarge),
          const SizedBox(height: 15),
          if (movil)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [documentos[0], const SizedBox(height: 12), documentos[1]],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: documentos[0]),
                const SizedBox(width: 12),
                Expanded(child: documentos[1]),
              ],
            ),
          const SizedBox(height: 32),
          if (movil)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [aprobar, const SizedBox(height: 10), rechazar],
            )
          else
            // Corrección del review: los botones centrados en la tarjeta.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 200, child: rechazar),
                const SizedBox(width: 16),
                SizedBox(width: 200, child: aprobar),
              ],
            ),
        ],
      ),
    );
  }
}

/// Una de las dos fotos. Al tocarla se abre en grande para revisarla bien.
class _Documento extends StatelessWidget {
  const _Documento({required this.url, required this.etiqueta});

  final String? url;
  final String etiqueta;

  void _ampliar(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url!)),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sinFoto = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.textoSecundario,
          ),
          const SizedBox(height: 6),
          Text('No se pudo cargar la foto', style: textos.bodySmall),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 230,
            color: AppColors.arena,
            child: url == null
                ? sinFoto
                : Semantics(
                    image: true,
                    label: etiqueta,
                    button: true,
                    child: InkWell(
                      onTap: () => _ampliar(context),
                      child: Image.network(
                        url!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, imagen, progreso) =>
                            progreso == null
                                ? imagen
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                        errorBuilder: (context, error, pila) => sinFoto,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(etiqueta, style: textos.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Pop-up para escribir el motivo del rechazo (corrección del review).
/// Devuelve el motivo, o null si el admin elige "Volver".
class _DialogoRechazo extends StatefulWidget {
  const _DialogoRechazo({required this.nombre});

  final String nombre;

  @override
  State<_DialogoRechazo> createState() => _DialogoRechazoState();
}

class _DialogoRechazoState extends State<_DialogoRechazo> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    // HU-33 c3: sin motivo no se rechaza.
    final error = VerificacionService.validarMotivo(_motivo.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_motivo.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('¿Rechazar esta verificación?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 380, maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.nombre} recibirá el motivo y podrá enviar documentos '
              'nuevos.',
              style: textos.bodyMedium,
            ),
            const SizedBox(height: 18),
            CampoTexto(
              etiqueta: 'Motivo del rechazo',
              pista: 'Ej.: la foto de la cédula no se lee',
              controller: _motivo,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirmar(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: textos.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton(
          style: AppTheme.botonPeligro,
          onPressed: _confirmar,
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
