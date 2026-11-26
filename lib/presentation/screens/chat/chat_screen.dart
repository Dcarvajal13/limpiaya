import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/estado_solicitud.dart';
import '../../../domain/entities/mensaje.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../../domain/entities/servicio_agendado.dart';
import '../../../domain/services/chat_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/mis_servicios_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';

/// HU-38 · Chat de un servicio entre el cliente y la trabajadora.
///
/// Criterios:
/// 1. Se llega desde "Escribir por el chat" del detalle del servicio.
/// 2. Los mensajes llegan en vivo (Realtime), con la fecha y la hora de cada
///    uno, y se pueden enviar mientras el chat esté abierto.
/// 3. Si el chat ya cerró, se puede leer pero no escribir; si no soy parte
///    del servicio, no se muestra la conversación.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.solicitudId});

  final String solicitudId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controlador = TextEditingController();
  final _scroll = ScrollController();
  final _pendientes = <Mensaje>[];

  int _siguienteTemporal = 0;
  bool _marcandoLeidos = false;

  @override
  void dispose() {
    _controlador.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Marca como leídos los mensajes de la otra parte (HU-38 c3).
  Future<void> _marcarLeidos(List<Mensaje> mensajes) async {
    final usuarioId = ref.read(sesionProvider).value?.id;
    if (usuarioId == null || _marcandoLeidos) return;
    final haySinLeer =
        mensajes.any((m) => !m.esMio(usuarioId) && m.leidoEn == null);
    if (!haySinLeer) return;

    _marcandoLeidos = true;
    await ref.read(chatRepositoryProvider).marcarLeidos(widget.solicitudId);
    _marcandoLeidos = false;
    if (!mounted) return;
    ref.invalidate(conversacionesProvider);
  }

  Future<void> _enviar() async {
    final texto = _controlador.text;
    final error = ChatService.validar(texto);
    if (error != null) {
      _avisar(error);
      return;
    }

    final usuarioId = ref.read(sesionProvider).value?.id;
    if (usuarioId == null) return;

    // HU-48 · Ocultar teléfonos, correos y wa.me en el envío optimista y avisar.
    final teniaContacto = ChatService.contieneContacto(texto);
    final textoSeguro = ChatService.ocultarContactos(texto.trim());

    // Envío optimista: la burbuja aparece ya y se quita si el envío falla.
    final temporal = Mensaje(
      id: --_siguienteTemporal,
      solicitudId: widget.solicitudId,
      autorId: usuarioId,
      contenido: textoSeguro,
      enviadoEn: DateTime.now(),
    );
    setState(() => _pendientes.add(temporal));
    _controlador.clear();

    final fallo = await ref
        .read(enviarMensajeProvider.notifier)
        .enviar(widget.solicitudId, texto);
    if (!mounted) return;

    setState(() => _pendientes.remove(temporal));
    if (fallo != null) {
      _avisar(fallo);
    } else if (teniaContacto) {
      _avisar(ChatService.avisoContactoOculto);
    }
    _bajar();
  }

  String _volverA(RolUsuario? rol) =>
      rol == RolUsuario.cliente ? Rutas.inicioCliente : Rutas.misServicios;

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final servicioAsync = ref.watch(servicioAgendadoProvider(widget.solicitudId));
    final mensajesAsync = ref.watch(mensajesProvider(widget.solicitudId));
    final movil = Responsive.esMovil(context);

    ref.listen(mensajesProvider(widget.solicitudId), (anterior, siguiente) {
      final lista = siguiente.value;
      if (lista == null) return;
      _marcarLeidos(lista);
      _bajar();
    });

    final servicio = servicioAsync.value;
    final titulo = servicio?.contraparteNombre == null
        ? 'Chat'
        : 'Chat con ${servicio!.contraparteNombre}';

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        title: Text(titulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(_volverA(sesion?.rol));
            }
          },
        ),
      ),
      body: _Ventana(
        movil: movil,
        child: servicioAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, _) => EstadoVacio(
            icono: Icons.wifi_off_rounded,
            titulo: error is AppException
                ? error.mensaje
                : 'No pudimos abrir el chat.',
            textoBoton: 'Reintentar',
            onPressed: () =>
                ref.invalidate(servicioAgendadoProvider(widget.solicitudId)),
          ),
          data: (servicio) {
            if (servicio == null) {
              return EstadoVacio(
                icono: Icons.lock_outline_rounded,
                titulo: ChatService.mensajeSinAcceso,
                mensaje: 'Solo el cliente y la trabajadora de este servicio '
                    'pueden ver la conversación.',
                textoBoton: 'Volver',
                onPressed: () => context.go(_volverA(sesion?.rol)),
              );
            }

            final mensajes = [
              ...?mensajesAsync.value,
              ..._pendientes,
            ];

            return Column(
              children: [
                _Cabecera(servicio: servicio, movil: movil),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.fondoChat,
                    child: mensajesAsync.hasError && mensajes.isEmpty
                      ? EstadoVacio(
                          icono: Icons.wifi_off_rounded,
                          titulo: 'No pudimos cargar los mensajes.',
                          textoBoton: 'Reintentar',
                          onPressed: () => ref.invalidate(
                            mensajesProvider(widget.solicitudId),
                          ),
                        )
                      : mensajes.isEmpty
                          ? EstadoVacio(
                              icono: Icons.chat_bubble_outline_rounded,
                              titulo: 'Todavía no hay mensajes',
                              mensaje: servicio.chatAbierto
                                  ? 'Escribe el primero para coordinar '
                                      'los detalles del servicio.'
                                  : 'Cuando el chat estaba abierto no se '
                                      'escribieron mensajes.',
                            )
                          : ListView.builder(
                              controller: _scroll,
                              padding: EdgeInsets.symmetric(
                                horizontal: movil ? 12 : 24,
                                vertical: 20,
                              ),
                              itemCount: mensajes.length,
                              itemBuilder: (context, indice) {
                                final mensaje = mensajes[indice];
                                final esMio =
                                    mensaje.esMio(sesion?.id ?? '');
                                // Mensajes seguidos de la misma persona van
                                // más juntos, como un solo bloque.
                                final seguido = indice > 0 &&
                                    mensajes[indice - 1].autorId ==
                                        mensaje.autorId;
                                return _Burbuja(
                                  mensaje: mensaje,
                                  esMio: esMio,
                                  seguido: seguido,
                                  pendiente:
                                      _pendientes.any((p) => p.id == mensaje.id),
                                );
                              },
                            ),
                  ),
                ),
                if (servicio.chatAbierto)
                  _CampoEnviar(
                    controlador: _controlador,
                    onEnviar: _enviar,
                  )
                else
                  const _ChatCerrado(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Franja con la otra parte y el servicio del que es el chat.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.servicio, required this.movil});

  final ServicioAgendado servicio;
  final bool movil;

  TonoInsignia get _tono => switch (servicio.estado) {
        EstadoSolicitud.publicada => TonoInsignia.azul,
        EstadoSolicitud.asignada => TonoInsignia.verde,
        EstadoSolicitud.completada => TonoInsignia.gris,
        EstadoSolicitud.cancelada => TonoInsignia.rojo,
      };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: movil ? 16 : 24,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(bottom: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        children: [
          AvatarUsuario(
            nombre: servicio.contraparteNombre ?? '?',
            fotoUrl: servicio.contraparteFotoUrl,
            tamano: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio.contraparteNombre ?? 'Sin nombre',
                  style: textos.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${servicio.tipo.servicio} · '
                  '${Formato.fechaLarga(servicio.inicio)}',
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textoSecundario,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InsigniaEstado(servicio.estado.etiqueta, tono: _tono),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja({
    required this.mensaje,
    required this.esMio,
    this.seguido = false,
    this.pendiente = false,
  });

  final Mensaje mensaje;
  final bool esMio;

  /// Va justo después de otro mensaje de la misma persona.
  final bool seguido;
  final bool pendiente;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ancho = MediaQuery.sizeOf(context).width;

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: seguido ? 3 : 14),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(maxWidth: ancho > 820 ? 520 : ancho * 0.78),
        decoration: BoxDecoration(
          color: esMio ? AppColors.primario : AppColors.superficie,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(esMio ? 18 : 6),
            bottomRight: Radius.circular(esMio ? 6 : 18),
          ),
          boxShadow: esMio
              ? null
              : [
                  BoxShadow(
                    color: AppColors.texto.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Opacity(
          opacity: pendiente ? 0.6 : 1,
          child: Column(
            crossAxisAlignment:
                esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                ChatService.ocultarContactos(mensaje.contenido),
                style: textos.bodyMedium?.copyWith(
                  color: esMio ? Colors.white : AppColors.texto,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pendiente
                    ? 'Enviando…'
                    : Formato.fechaHoraCorta(mensaje.enviadoEn),
                style: textos.labelSmall?.copyWith(
                  color: esMio
                      ? AppColors.textoSobreOscuro
                      : AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampoEnviar extends StatelessWidget {
  const _CampoEnviar({
    required this.controlador,
    required this.onEnviar,
  });

  final TextEditingController controlador;
  final Future<void> Function() onEnviar;

  static OutlineInputBorder _borde(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: color, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('campo-mensaje'),
                controller: controlador,
                minLines: 1,
                maxLines: 4,
                maxLength: ChatService.maxCaracteres,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onEnviar(),
                buildCounter: (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) =>
                    null,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.fondoChat,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: _borde(Colors.transparent),
                  enabledBorder: _borde(Colors.transparent),
                  focusedBorder: _borde(AppColors.primario),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              key: const Key('enviar-mensaje'),
              tooltip: 'Enviar',
              onPressed: onEnviar,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatCerrado extends StatelessWidget {
  const _ChatCerrado();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.textoSecundario,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${ChatService.mensajeCerrado} Puedes leer lo que se '
                'dijeron, pero no enviar mensajes nuevos.',
                style: textos.bodySmall?.copyWith(
                  color: AppColors.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marco del chat. En computadora es una ventana blanca redondeada que se
/// separa del fondo de la página; en el teléfono ocupa toda la pantalla.
class _Ventana extends StatelessWidget {
  const _Ventana({required this.movil, required this.child});

  final bool movil;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (movil) {
      return ColoredBox(color: AppColors.superficie, child: child);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borde),
              boxShadow: [
                BoxShadow(
                  color: AppColors.texto.withValues(alpha: 0.08),
                  blurRadius: 40,
                  spreadRadius: -12,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: SizedBox.expand(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
