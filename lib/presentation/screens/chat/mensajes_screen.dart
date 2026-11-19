import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/services/chat_service.dart';
import '../../../domain/entities/conversacion.dart';
import '../../../domain/entities/rol_usuario.dart';
import '../../providers/chat_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';
import '../../widgets/estado_vacio.dart';
import '../cliente/barra_cliente.dart';
import '../trabajadora/barra_trabajadora.dart';

/// HU-38 c3 · Lista de conversaciones ("Mensajes").
///
/// Muestra, por cada servicio con chat, la otra parte, lo último que se
/// dijeron y cuántos mensajes de la otra parte siguen sin leer. Se llega
/// desde la pestaña "Mensajes" de la barra, en los dos roles.
class MensajesScreen extends ConsumerWidget {
  const MensajesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider).value;
    final esTrabajadora = sesion?.rol == RolUsuario.trabajadora;
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final conversaciones = ref.watch(conversacionesProvider);
    final noLeidos = ref.watch(noLeidosProvider);

    final barra = esTrabajadora
        ? BarraTrabajadora(
            nombre: sesion?.nombre ?? '',
            fotoUrl: sesion?.fotoUrl,
            noLeidos: noLeidos,
          )
        : BarraCliente(
            nombre: sesion?.nombre ?? '',
            fotoUrl: sesion?.fotoUrl,
            noLeidos: noLeidos,
          );

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          barra,
          Expanded(
            child: DesplazableConPie(
              child: ContenidoCentrado(
                vertical: movil ? 20 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mensajes',
                      style: textos.displaySmall?.copyWith(
                        fontSize: movil ? 34 : 44,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Habla con la otra parte de cada servicio.',
                      style: textos.bodyLarge
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    conversaciones.when(
                      loading: () => const _Caja(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (error, _) => _Caja(
                        child: EstadoVacio(
                          icono: Icons.wifi_off_rounded,
                          titulo: error is AppException
                              ? error.mensaje
                              : 'No pudimos cargar tus mensajes.',
                          textoBoton: 'Reintentar',
                          onPressed: () =>
                              ref.invalidate(conversacionesProvider),
                        ),
                      ),
                      data: (lista) {
                        if (lista.isEmpty) {
                          return _Caja(
                            child: EstadoVacio(
                              icono: Icons.forum_outlined,
                              titulo: 'Aún no tienes mensajes',
                              mensaje: 'Abre un servicio agendado y toca '
                                  '"Escribir por el chat". La conversación '
                                  'aparecerá aquí.',
                              textoBoton: 'Ver mis servicios',
                              onPressed: () => context.go(
                                esTrabajadora
                                    ? Rutas.misServicios
                                    : Rutas.inicioCliente,
                              ),
                            ),
                          );
                        }

                        final bandeja = _Caja(
                          child: Column(
                            children: [
                              for (final (i, conversacion) in lista.indexed) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 78,
                                    endIndent: 20,
                                  ),
                                _FilaConversacion(conversacion: conversacion),
                              ],
                            ],
                          ),
                        );

                        // En pantallas anchas, la lista no se estira de
                        // borde a borde: al lado van los consejos.
                        if (MediaQuery.sizeOf(context).width >= 1000) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: bandeja),
                              const SizedBox(width: 28),
                              const SizedBox(width: 340, child: _Consejos()),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            bandeja,
                            const SizedBox(height: 20),
                            const _Consejos(),
                          ],
                        );
                      },
                    ),
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

class _FilaConversacion extends StatelessWidget {
  const _FilaConversacion({required this.conversacion});

  final Conversacion conversacion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final hayNoLeidos = conversacion.noLeidos > 0;
    final ultimo = conversacion.ultimoMensaje;

    return Material(
      color: hayNoLeidos ? AppColors.seleccionSuave : Colors.transparent,
      child: InkWell(
        key: Key('conversacion-${conversacion.solicitudId}'),
        onTap: () =>
            context.push(Rutas.chatServicio(conversacion.solicitudId)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUsuario(
                nombre: conversacion.contraparteNombre,
                fotoUrl: conversacion.contraparteFotoUrl,
                tamano: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversacion.contraparteNombre,
                            style: textos.titleMedium?.copyWith(
                              fontWeight:
                                  hayNoLeidos ? FontWeight.w700 : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversacion.ultimoEn != null)
                          Text(
                            Formato.fechaHoraCorta(conversacion.ultimoEn!),
                            style: textos.bodySmall?.copyWith(
                              color: hayNoLeidos
                                  ? AppColors.primario
                                  : AppColors.textoSecundario,
                              fontWeight: hayNoLeidos
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${conversacion.tipo.servicio} · '
                      '${Formato.diaCorto(conversacion.inicio)}',
                      style: textos.bodySmall?.copyWith(
                        color: AppColors.textoSecundario,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ultimo == null
                                ? 'Todavía no hay mensajes'
                                : '${conversacion.ultimoEsMio ? 'Tú: ' : ''}$ultimo',
                            style: textos.bodyMedium?.copyWith(
                              color: hayNoLeidos
                                  ? AppColors.texto
                                  : AppColors.textoSecundario,
                              fontWeight:
                                  hayNoLeidos ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hayNoLeidos) ...[
                          const SizedBox(width: 10),
                          Container(
                            key: Key(
                              'no-leidos-${conversacion.solicitudId}',
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primario,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${conversacion.noLeidos}',
                              style: textos.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
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

class _Caja extends StatelessWidget {
  const _Caja({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Material (y no Container) para que el efecto al tocar una fila se vea
    // encima del blanco y respete las esquinas redondeadas.
    return Material(
      color: AppColors.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// Qué conviene acordar por el chat antes de un servicio.
class _Consejos extends StatelessWidget {
  const _Consejos();

  static const _puntos = [
    (Icons.schedule_rounded, 'La hora de llegada y cuánto dura el servicio.'),
    (Icons.location_on_outlined, 'Cómo llegar y el punto de referencia.'),
    (Icons.payments_outlined, 'El método de pago y el monto acordado.'),
    (
      Icons.lock_outline_rounded,
      'Los teléfonos no se muestran: todo se coordina aquí.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.arena,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Antes del servicio, confirma', style: textos.headlineSmall),
          const SizedBox(height: 16),
          for (final (icono, texto) in _puntos)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icono, size: 20, color: AppColors.primario),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      texto,
                      style: textos.bodyMedium?.copyWith(color: AppColors.texto),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Cada chat sigue abierto hasta ${ChatService.diasChatAbierto} días '
            'después de terminado o cancelado el servicio.',
            style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
          ),
        ],
      ),
    );
  }
}
