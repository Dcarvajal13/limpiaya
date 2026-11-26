import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/aviso.dart';
import '../../../domain/entities/correo_aviso.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../../domain/services/aviso_service.dart';
import '../../providers/avisos_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';

/// HU-50 (Campana de avisos en la app) y HU-49 (Avisos por correo).
class AvisosScreen extends ConsumerStatefulWidget {
  const AvisosScreen({super.key});

  @override
  ConsumerState<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends ConsumerState<AvisosScreen> {
  bool _marcandoTodos = false;
  bool _guardandoPreferencia = false;

  Future<void> _marcarTodos() async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _marcandoTodos = true);
    try {
      await ref.read(avisoRepositoryProvider).marcarTodosLeidos();
      ref.invalidate(avisosProvider);
      mensajes.showSnackBar(
        const SnackBar(content: Text('Todos los avisos marcados como leídos.')),
      );
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _marcandoTodos = false);
    }
  }

  Future<void> _abrirAviso(Aviso aviso) async {
    if (!aviso.leido) {
      await ref.read(avisoRepositoryProvider).marcarLeido(aviso.id);
      ref.invalidate(avisosProvider);
    }
    if (!mounted) return;
    final ruta = aviso.ruta;
    if (ruta != null && ruta.isNotEmpty) {
      context.go(ruta);
    }
  }

  Future<void> _cambiarAvisosCorreo(bool activo) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _guardandoPreferencia = true);
    try {
      await ref.read(avisoRepositoryProvider).actualizarAvisosCorreo(activo);
      ref.invalidate(sesionProvider);
      mensajes.showSnackBar(
        SnackBar(
          content: Text(
            activo
                ? 'Avisos por correo activados.'
                : 'Avisos por correo desactivados.',
          ),
        ),
      );
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardandoPreferencia = false);
    }
  }

  String _inicioDe(RolUsuario? rol) => switch (rol) {
        RolUsuario.cliente => Rutas.inicioCliente,
        RolUsuario.trabajadora => Rutas.inicioTrabajadora,
        RolUsuario.admin => Rutas.inicioAdmin,
        null => Rutas.inicio,
      };

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final avisosAsync = ref.watch(avisosProvider);
    final correosAsync = ref.watch(correosAvisoProvider);
    final noLeidos = AvisoService.contarNoLeidos(avisosAsync.value ?? const []);
    final textos = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.fondo,
        appBar: AppBar(
          title: const Text('Avisos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(_inicioDe(sesion?.rol));
              }
            },
          ),
          actions: [
            if (noLeidos > 0)
              TextButton.icon(
                onPressed: _marcandoTodos ? null : _marcarTodos,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Marcar todos'),
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                text: noLeidos > 0
                    ? 'En la app ($noLeidos)'
                    : 'En la app',
              ),
              const Tab(text: 'Por correo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1 · HU-50: Campana de avisos en la app
            avisosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => EstadoVacio(
                icono: Icons.wifi_off_rounded,
                titulo: 'No pudimos cargar tus avisos',
                mensaje: error is AppException ? error.mensaje : null,
                textoBoton: 'Reintentar',
                onPressed: () => ref.invalidate(avisosProvider),
              ),
              data: (lista) {
                if (lista.isEmpty) {
                  return const EstadoVacio(
                    icono: Icons.notifications_none_rounded,
                    titulo: 'Sin avisos por ahora',
                    mensaje:
                        'Aquí verás novedades sobre postulaciones, elecciones '
                        'y cambios en tus servicios.',
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ContenidoCentrado(
                    anchoMaximo: 820,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final aviso in lista) ...[
                          _TarjetaAviso(
                            aviso: aviso,
                            onTap: () => _abrirAviso(aviso),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // Pestaña 2 · HU-49: Avisos por correo
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ContenidoCentrado(
                anchoMaximo: 820,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Avisos por correo electrónico',
                                        style: textos.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Te enviamos correos ante eventos '
                                        'importantes de tus solicitudes y '
                                        'servicios.',
                                        style: textos.bodySmall?.copyWith(
                                          color: AppColors.textoSecundario,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: sesion?.avisosCorreo ?? true,
                                  onChanged: _guardandoPreferencia
                                      ? null
                                      : _cambiarAvisosCorreo,
                                ),
                              ],
                            ),
                            const Divider(height: 28),
                            Text(
                              'Eventos incluidos',
                              style: textos.labelLarge,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final tipo in TipoCorreoAviso.values)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.mail_outline_rounded,
                                      size: 16,
                                      color: AppColors.primario,
                                    ),
                                    label: Text(tipo.etiqueta),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Historial de avisos por correo',
                        style: textos.titleMedium),
                    const SizedBox(height: 10),
                    correosAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => EstadoVacio(
                        icono: Icons.mail_outline_rounded,
                        titulo: 'No pudimos cargar el historial de correos',
                        mensaje: error is AppException ? error.mensaje : null,
                        textoBoton: 'Reintentar',
                        onPressed: () => ref.invalidate(correosAvisoProvider),
                      ),
                      data: (correos) {
                        if (correos.isEmpty) {
                          return const EstadoVacio(
                            icono: Icons.mark_email_read_outlined,
                            titulo: 'Todavía no se han generado correos',
                            mensaje:
                                'Cuando recibas una postulación, seas elegida, '
                                'tengas un recordatorio de 24 h o se cancele '
                                'un servicio, aparecerá aquí.',
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final correo in correos) ...[
                              _TarjetaCorreo(correo: correo),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaAviso extends StatelessWidget {
  const _TarjetaAviso({required this.aviso, required this.onTap});

  final Aviso aviso;
  final VoidCallback onTap;

  IconData get _icono => switch (aviso.tipo) {
        TipoAviso.postulacion => Icons.person_add_alt_1_outlined,
        TipoAviso.eleccion => Icons.check_circle_outline_rounded,
        TipoAviso.cancelacion => Icons.cancel_outlined,
        TipoAviso.completada => Icons.task_alt_rounded,
        TipoAviso.recordatorio => Icons.alarm_rounded,
        TipoAviso.cuenta => Icons.shield_outlined,
        TipoAviso.sistema => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sinLeer = !aviso.leido;

    return Card(
      color: sinLeer ? AppColors.seleccionSuave : AppColors.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: sinLeer ? AppColors.primario : AppColors.borde,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:
                    sinLeer ? AppColors.primarioClaro : AppColors.arena,
                foregroundColor: AppColors.primario,
                child: Icon(_icono, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            aviso.titulo,
                            style: textos.titleSmall?.copyWith(
                              fontWeight:
                                  sinLeer ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (sinLeer)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.acentoTexto,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(aviso.mensaje, style: textos.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      Formato.fechaHoraCorta(aviso.creadoEn),
                      style: textos.labelSmall?.copyWith(
                        color: AppColors.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaCorreo extends StatelessWidget {
  const _TarjetaCorreo({required this.correo});

  final CorreoAviso correo;

  TonoInsignia get _tono => switch (correo.estado) {
        EstadoCorreoAviso.enviado => TonoInsignia.verde,
        EstadoCorreoAviso.pendiente => TonoInsignia.ambar,
        EstadoCorreoAviso.cancelado => TonoInsignia.gris,
        EstadoCorreoAviso.error => TonoInsignia.rojo,
      };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    correo.asunto,
                    style: textos.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                InsigniaEstado(correo.estado.etiqueta, tono: _tono),
              ],
            ),
            const SizedBox(height: 6),
            Text(correo.cuerpo, style: textos.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  'Tipo: ${correo.tipo.etiqueta}',
                  style: textos.labelSmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                ),
                Text(
                  'Programado: ${Formato.fechaHoraCorta(correo.programadoPara)}',
                  style: textos.labelSmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
