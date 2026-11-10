import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/orden_trabajadoras.dart';
import '../../../domain/entities/perfil_publico.dart';
import '../../../domain/entities/solicitud.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/busqueda_service.dart';
import '../../providers/buscar_trabajadoras_provider.dart';
import '../../providers/mis_solicitudes_provider.dart';
import '../../providers/publicar_solicitud_provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_destacada.dart';
import '../../widgets/insignia_verificada.dart';
import 'barra_cliente.dart';
import 'dialogo_invitar.dart';

/// HU-25 · Buscar trabajadoras ('/cliente/buscar').
///
/// 1. Filtrar por zona: solo salen las que trabajan en esa zona.
/// 2. Ordenar por calificación: de mayor a menor promedio.
/// 3. "Invitar": elige una solicitud Publicada y ella la ve marcada como
///    "Te invitaron".
/// 4. Sin resultados: "No hay trabajadoras con esos filtros".
///
/// Solo aparecen trabajadoras con la identidad verificada.
class BuscarTrabajadorasScreen extends ConsumerStatefulWidget {
  const BuscarTrabajadorasScreen({super.key});

  @override
  ConsumerState<BuscarTrabajadorasScreen> createState() =>
      _BuscarTrabajadorasScreenState();
}

class _BuscarTrabajadorasScreenState
    extends ConsumerState<BuscarTrabajadorasScreen> {
  int? _zonaId;
  OrdenTrabajadoras _orden = OrdenTrabajadoras.calificacion;

  Future<void> _invitar(PerfilPublico trabajadora) async {
    final mensajero = ScaffoldMessenger.of(context);
    final List<Solicitud> solicitudes;
    try {
      solicitudes = await ref.read(misSolicitudesProvider.future);
    } on Exception {
      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('No pudimos cargar tus solicitudes.')),
        );
      return;
    }
    if (!mounted) return;

    final resultado = await mostrarDialogoInvitar(
      context,
      trabajadora: trabajadora,
      publicadas: BusquedaService.publicadas(solicitudes),
      disponibles:
          BusquedaService.solicitudesParaInvitar(solicitudes, trabajadora),
    );
    if (!mounted) return;

    switch (resultado) {
      case ResultadoInvitar.invitada:
        mensajero
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(mensajeInvitada(trabajadora))));
      case ResultadoInvitar.irAPublicar:
        context.go(Rutas.publicarSolicitud);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;
    final resultado = ref.watch(buscarTrabajadorasProvider(_zonaId));
    final zonas = ref.watch(zonasCatalogoProvider).value ?? const <Zona>[];
    // Se carga desde ya para que "Invitar" abra sin esperar (c3).
    ref.watch(misSolicitudesProvider);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Column(
        children: [
          BarraCliente(nombre: sesion?.nombre ?? '', fotoUrl: sesion?.fotoUrl),
          Expanded(
            child: SingleChildScrollView(
              child: ContenidoCentrado(
                vertical: movil ? 20 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buscar trabajadoras',
                      style:
                          (movil ? textos.headlineLarge : textos.displaySmall)
                              ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Encuentra a alguien de confianza en tu zona e invítala '
                      'a tu solicitud.',
                      style: textos.bodyLarge
                          ?.copyWith(color: AppColors.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    _Filtros(
                      zonas: zonas,
                      zonaId: _zonaId,
                      orden: _orden,
                      movil: movil,
                      onZona: (id) => setState(() => _zonaId = id),
                      onOrden: (orden) => setState(() => _orden = orden),
                    ),
                    const SizedBox(height: 20),
                    resultado.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _Caja(
                        child: EstadoVacio(
                          icono: Icons.wifi_off_rounded,
                          titulo: error is AppException
                              ? error.mensaje
                              : BusquedaService.mensajeError,
                          textoBoton: 'Reintentar',
                          onPressed: () => ref
                              .invalidate(buscarTrabajadorasProvider(_zonaId)),
                        ),
                      ),
                      data: (lista) => lista.isEmpty
                          // c4 · Sin resultados.
                          ? _Caja(
                              child: EstadoVacio(
                                icono: Icons.person_search_outlined,
                                titulo: BusquedaService.sinResultados,
                                mensaje: _zonaId == null
                                    ? null
                                    : 'Prueba con otra zona.',
                                textoBoton:
                                    _zonaId == null ? null : 'Ver todas las zonas',
                                onPressed: _zonaId == null
                                    ? null
                                    : () => setState(() => _zonaId = null),
                              ),
                            )
                          : _Resultados(
                              trabajadoras:
                                  BusquedaService.ordenar(lista, _orden),
                              movil: movil,
                              onVerPerfil: (t) => context
                                  .push(Rutas.perfilPublicoTrabajadora(t.id)),
                              onInvitar: _invitar,
                            ),
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

/// c1 y c2 · Zona y orden.
class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.zonas,
    required this.zonaId,
    required this.orden,
    required this.movil,
    required this.onZona,
    required this.onOrden,
  });

  final List<Zona> zonas;
  final int? zonaId;
  final OrdenTrabajadoras orden;
  final bool movil;
  final ValueChanged<int?> onZona;
  final ValueChanged<OrdenTrabajadoras> onOrden;

  @override
  Widget build(BuildContext context) {
    final ordenadas = [...zonas]
      ..sort((a, b) {
        final m = a.municipio.compareTo(b.municipio);
        return m != 0 ? m : a.nombre.compareTo(b.nombre);
      });

    final campoZona = DropdownButtonFormField<int?>(
      // La clave cambia con el valor para que "Ver todas las zonas" lo
      // limpie desde afuera.
      key: ValueKey('filtro-zona-$zonaId'),
      initialValue: zonaId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Zona',
        prefixIcon: Icon(Icons.place_outlined),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Todas las zonas'),
        ),
        for (final z in ordenadas)
          DropdownMenuItem<int?>(
            value: z.id,
            child: Text(
              z.municipio.isEmpty ? z.nombre : '${z.nombre} · ${z.municipio}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onZona,
    );

    final campoOrden = DropdownButtonFormField<OrdenTrabajadoras>(
      key: const Key('orden-trabajadoras'),
      initialValue: orden,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ordenar por',
        prefixIcon: Icon(Icons.sort_rounded),
      ),
      items: [
        for (final o in OrdenTrabajadoras.values)
          DropdownMenuItem(
            value: o,
            child: Text(o.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (valor) {
        if (valor != null) onOrden(valor);
      },
    );

    return _Caja(
      padding: const EdgeInsets.all(16),
      child: movil
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [campoZona, const SizedBox(height: 12), campoOrden],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: campoZona),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: campoOrden),
              ],
            ),
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({
    required this.trabajadoras,
    required this.movil,
    required this.onVerPerfil,
    required this.onInvitar,
  });

  final List<PerfilPublico> trabajadoras;
  final bool movil;
  final ValueChanged<PerfilPublico> onVerPerfil;
  final ValueChanged<PerfilPublico> onInvitar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cantidad = trabajadoras.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          cantidad == 1 ? '1 trabajadora' : '$cantidad trabajadoras',
          style: textos.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primarioOscuro,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, restricciones) {
            final columnas = restricciones.maxWidth >= 760 ? 2 : 1;
            const espacio = 16.0;
            final ancho =
                (restricciones.maxWidth - espacio * (columnas - 1)) / columnas;
            return Wrap(
              spacing: espacio,
              runSpacing: espacio,
              children: [
                for (final t in trabajadoras)
                  SizedBox(
                    width: ancho,
                    child: _TarjetaTrabajadora(
                      trabajadora: t,
                      onVerPerfil: () => onVerPerfil(t),
                      onInvitar: () => onInvitar(t),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TarjetaTrabajadora extends StatelessWidget {
  const _TarjetaTrabajadora({
    required this.trabajadora,
    required this.onVerPerfil,
    required this.onInvitar,
  });

  final PerfilPublico trabajadora;
  final VoidCallback onVerPerfil;
  final VoidCallback onInvitar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final t = trabajadora;
    final reputacion = t.tieneResenas
        ? '★ ${Formato.promedio(t.promedio!)} · '
            '${t.totalResenas == 1 ? '1 reseña' : '${t.totalResenas} reseñas'}'
        : 'Nueva en la plataforma';
    final datos = [
      t.serviciosCompletados == 1
          ? '1 servicio completado'
          : '${t.serviciosCompletados} servicios completados',
      if (t.experienciaAnios != null && t.experienciaAnios! > 0)
        t.experienciaAnios == 1
            ? '1 año de experiencia'
            : '${t.experienciaAnios} años de experiencia',
    ].join(' · ');
    final zonas = t.zonas.length <= 3
        ? t.zonas.join(', ')
        : '${t.zonas.take(3).join(', ')} y ${t.zonas.length - 3} más';
    final primerNombre = t.nombre.trim().split(RegExp(r'\s+')).first;

    return Container(
      key: Key('trabajadora-${t.id}'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarUsuario(nombre: t.nombre, fotoUrl: t.fotoUrl, tamano: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (t.verificada) ...[
                          const SizedBox(width: 6),
                          const InsigniaVerificada(compacta: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reputacion,
                      style: textos.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.texto,
                      ),
                    ),
                    if (t.destacada) ...[
                      const SizedBox(height: 6),
                      const InsigniaDestacada(),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            datos,
            style: textos.bodySmall?.copyWith(color: AppColors.textoSecundario),
          ),
          if (zonas.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AppColors.textoSecundario,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    zonas,
                    style: textos.bodySmall
                        ?.copyWith(color: AppColors.textoSecundario),
                  ),
                ),
              ],
            ),
          ],
          if (t.tarifaReferencia != null) ...[
            const SizedBox(height: 6),
            Text(
              'Desde ${Formato.dinero(t.tarifaReferencia!)} por hora',
              style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('ver-perfil-${t.id}'),
                  onPressed: onVerPerfil,
                  child: const Text('Ver perfil'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  key: Key('invitar-${t.id}'),
                  onPressed: onInvitar,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    'Invitar',
                    semanticsLabel: 'Invitar a $primerNombre',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  const _Caja({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: child,
    );
  }
}
