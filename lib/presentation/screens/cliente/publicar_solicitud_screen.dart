import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../domain/entities/metodo_pago.dart';
import '../../../domain/entities/nueva_solicitud.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/quien_pone_productos.dart';
import '../../../domain/entities/solicitud.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/solicitud_service.dart';
import '../../providers/publicar_solicitud_provider.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/selector_zona.dart';

/// HU-07 · Publicar una solicitud de limpieza (incluye HU-43 y HU-52).
///
/// Con [solicitudId] es HU-09 · Editar una solicitud publicada (Figma:
/// "Editar solicitud", mismo formulario con "Guardar cambios").
///
/// Con [repetirDe] es HU-44 · Repetir una solicitud anterior: el formulario
/// sale con los mismos datos y la fecha vacía, y al publicar se crea una
/// solicitud nueva (la anterior no cambia).
///
/// Feedback del Product Review: en pantalla grande, el formulario va a la
/// izquierda y a la derecha dos cajas (vista previa y pago), todo al mismo
/// nivel y sin espacio en blanco.
class PublicarSolicitudScreen extends ConsumerStatefulWidget {
  const PublicarSolicitudScreen({super.key, this.solicitudId, this.repetirDe})
      : assert(
          solicitudId == null || repetirDe == null,
          'Se edita o se repite, no las dos cosas',
        );

  /// Id de la solicitud a editar, o null para publicar una nueva.
  final String? solicitudId;

  /// HU-44 · Id de la solicitud Completada o Cancelada que se repite.
  final String? repetirDe;

  @override
  ConsumerState<PublicarSolicitudScreen> createState() =>
      _PublicarSolicitudScreenState();
}

class _PublicarSolicitudScreenState
    extends ConsumerState<PublicarSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _direccion = TextEditingController();
  final _pago = TextEditingController(text: '30');

  // Claves para desplazamiento interactivo al faltar datos.
  final _fechaKey = GlobalKey();
  final _zonaKey = GlobalKey();
  final _direccionKey = GlobalKey();
  final _productosKey = GlobalKey();
  final _pagoKey = GlobalKey();

  /// Null solo al repetir (HU-44 c1): hay que elegir la fecha nueva.
  DateTime? _fecha;
  TimeOfDay _hora = const TimeOfDay(hour: 9, minute: 0);
  int _horas = 4;
  TipoLimpieza _tipo = TipoLimpieza.general;
  int? _zonaId;
  int _habitaciones = 2;
  int _banos = 1;
  bool _mascotas = false;
  QuienPoneProductos? _productos;
  MetodoPago _metodo = MetodoPago.pagoMovil;
  bool _intentoEnviar = false;

  /// HU-09: la solicitud tal como estaba antes de editarla.
  Solicitud? _original;

  /// HU-44: la solicitud que se está repitiendo.
  Solicitud? _base;

  bool get _editando => widget.solicitudId != null;
  bool get _repitiendo => widget.repetirDe != null;

  @override
  void initState() {
    super.initState();
    if (!_repitiendo) _fecha = _manana();
    _direccion.addListener(() => setState(() {}));
    _pago.addListener(() => setState(() {}));

    // HU-09: al editar, el formulario se llena cuando llega la solicitud.
    // Se hace aquí y no en build porque cambiar el texto de un campo avisa
    // a sus listeners, y eso no se puede durante build.
    if (_editando) {
      ref.listenManual(
        solicitudParaEditarProvider(widget.solicitudId!),
        (anterior, actual) {
          final solicitud = actual.value;
          if (solicitud == null || _original != null || !mounted) return;
          _sembrar(solicitud);
          setState(() {});
        },
        fireImmediately: true,
      );
      return;
    }

    // HU-44 c1: al repetir, el formulario se llena con los mismos datos y
    // la fecha queda vacía.
    if (_repitiendo) {
      ref.listenManual(
        solicitudParaEditarProvider(widget.repetirDe!),
        (anterior, actual) {
          final solicitud = actual.value;
          if (solicitud == null || _base != null || !mounted) return;
          _sembrar(solicitud, repetir: true);
          setState(() {});
        },
        fireImmediately: true,
      );
      return;
    }

    // HU-05 c2: zona y dirección precargadas, y se pueden cambiar.
    ref.read(direccionGuardadaProvider.future).then((guardada) {
      if (!mounted || guardada == null) return;
      setState(() {
        _zonaId ??= guardada.zonaId;
        if (_direccion.text.isEmpty && guardada.direccion != null) {
          _direccion.text = guardada.direccion!;
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _direccion.dispose();
    _pago.dispose();
    super.dispose();
  }

  static DateTime _manana() {
    final manana = DateTime.now().add(const Duration(days: 1));
    return DateTime(manana.year, manana.month, manana.day);
  }

  /// HU-09 · Llena el formulario con la solicitud a editar (una sola vez).
  /// HU-44 · Con [repetir], copia todo menos la fecha.
  void _sembrar(Solicitud solicitud, {bool repetir = false}) {
    if (_original != null || _base != null) return;
    final inicio = solicitud.inicio;
    if (repetir) {
      _base = solicitud;
      _fecha = null;
    } else {
      _original = solicitud;
      _fecha = DateTime(inicio.year, inicio.month, inicio.day);
    }
    _hora = TimeOfDay(hour: inicio.hour, minute: inicio.minute);
    _horas = solicitud.horasEstimadas.round();
    _tipo = solicitud.tipo;
    _zonaId = solicitud.zonaId;
    _direccion.text = solicitud.direccion ?? '';
    final pago = solicitud.pagoOfrecido;
    _pago.text = pago == pago.roundToDouble()
        ? pago.toStringAsFixed(0)
        : pago.toStringAsFixed(2);
    _habitaciones = solicitud.habitaciones;
    _banos = solicitud.banos;
    _mascotas = solicitud.tieneMascotas;
    _productos = solicitud.productosPor;
    _metodo = solicitud.metodoPago;
  }

  /// HU-09 c3 · Confirmar cuando las postulantes verán otra fecha, hora o pago.
  Future<bool> _confirmarCambios(int postulantes) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Guardar los cambios?'),
        content: Text(
          postulantes == 1
              ? 'Ya tienes 1 postulante. Verá la fecha, la hora o el pago '
                  'nuevos.'
              : 'Ya tienes $postulantes postulantes. Verán la fecha, la hora '
                  'o el pago nuevos.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
    return respuesta ?? false;
  }

  /// Null mientras no haya fecha (HU-44).
  DateTime? get _inicio {
    final fecha = _fecha;
    if (fecha == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, _hora.hour, _hora.minute);
  }

  double get _montoPago =>
      double.tryParse(_pago.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _elegirFecha() async {
    try {
      final hoy = DateTime.now();
      final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
      final primerDia = hoySoloFecha;
      final limiteFuturo = hoySoloFecha.add(const Duration(days: 365));
      final ultimoDia = (_fecha != null && _fecha!.isAfter(limiteFuturo))
          ? _fecha!.add(const Duration(days: 30))
          : limiteFuturo;

      final fechaBase = (_fecha != null && !_fecha!.isBefore(primerDia))
          ? _fecha!
          : _manana();
      final fechaInicial =
          fechaBase.isAfter(ultimoDia) ? ultimoDia : fechaBase;

      final elegida = await showDatePicker(
        context: context,
        initialDate: fechaInicial,
        firstDate: primerDia,
        lastDate: ultimoDia,
      );
      if (elegida != null) setState(() => _fecha = elegida);
    } catch (e) {
      debugPrint('Error al abrir selector de fecha: $e');
    }
  }

  Future<void> _elegirHora() async {
    try {
      final elegida =
          await showTimePicker(context: context, initialTime: _hora);
      if (elegida != null) setState(() => _hora = elegida);
    } catch (e) {
      debugPrint('Error al abrir selector de hora: $e');
    }
  }

  List<({String nombre, GlobalKey key})> _camposFaltantes() {
    final faltantes = <({String nombre, GlobalKey key})>[];
    final inicio = _inicio;
    if (inicio == null) {
      faltantes.add((nombre: 'Fecha del servicio', key: _fechaKey));
    } else if (!inicio.isAfter(DateTime.now())) {
      faltantes.add((nombre: 'Fecha futura', key: _fechaKey));
    }
    if (_zonaId == null) {
      faltantes.add((nombre: 'Zona o urbanización', key: _zonaKey));
    }
    if (_direccion.text.trim().length < 5) {
      faltantes.add((nombre: 'Dirección completa', key: _direccionKey));
    }
    if (_productos == null) {
      faltantes.add((nombre: 'Quién pone los productos', key: _productosKey));
    }
    if (_montoPago <= 0) {
      faltantes.add((nombre: 'Pago ofrecido', key: _pagoKey));
    }
    return faltantes;
  }

  void _irACampo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  Future<void> _publicar() async {
    setState(() => _intentoEnviar = true);
    final valido = _formKey.currentState!.validate();
    final inicio = _inicio;
    final faltantes = _camposFaltantes();

    if (!valido ||
        _zonaId == null ||
        _productos == null ||
        inicio == null ||
        !inicio.isAfter(DateTime.now())) {
      if (faltantes.isNotEmpty) {
        _irACampo(faltantes.first.key);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Faltan datos obligatorios: ${faltantes.map((e) => e.nombre).join(', ')}.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    final solicitud = NuevaSolicitud(
      tipo: _tipo,
      zonaId: _zonaId!,
      direccion: _direccion.text.trim(),
      inicio: inicio,
      horasEstimadas: _horas.toDouble(),
      pagoOfrecido: _montoPago,
      metodoPago: _metodo,
      habitaciones: _habitaciones,
      banos: _banos,
      tieneMascotas: _mascotas,
      productosPor: _productos,
      // Al editar (o repetir, HU-44) se conservan los datos que este
      // formulario no muestra.
      puntoReferencia: (_original ?? _base)?.puntoReferencia,
      notas: (_original ?? _base)?.notas,
    );

    final original = _original;
    if (_editando && original != null) {
      if (original.numPostulantes > 0 &&
          SolicitudService.cambiaFechaHoraOPago(original, solicitud) &&
          !await _confirmarCambios(original.numPostulantes)) {
        return;
      }
      final guardado = await ref
          .read(publicarSolicitudProvider.notifier)
          .editar(original, solicitud);
      if (!mounted || !guardado) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cambios guardados. Las trabajadoras ya ven la versión actualizada.',
          ),
        ),
      );
      context.go(Rutas.inicioCliente);
      return;
    }

    final ok =
        await ref.read(publicarSolicitudProvider.notifier).publicar(solicitud);
    if (!mounted || !ok) return;

    // H1: confirmar que la acción terminó bien.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '¡Solicitud publicada! Las trabajadoras de tu zona ya la pueden ver.',
        ),
      ),
    );
    context.go(Rutas.inicioCliente);
  }

  @override
  Widget build(BuildContext context) {
    if (_editando) {
      final cargada = ref.watch(solicitudParaEditarProvider(widget.solicitudId!));
      final aviso = switch (cargada) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final error) => EstadoVacio(
            icono: Icons.wifi_off_rounded,
            titulo: error is AppException
                ? error.mensaje
                : 'No pudimos cargar la solicitud.',
            textoBoton: 'Volver a Mis solicitudes',
            onPressed: () => context.go(Rutas.inicioCliente),
          ),
        AsyncData(:final value) when value == null => EstadoVacio(
            icono: Icons.search_off_rounded,
            titulo: 'No encontramos esta solicitud',
            textoBoton: 'Volver a Mis solicitudes',
            onPressed: () => context.go(Rutas.inicioCliente),
          ),
        // HU-09 c2: con trabajadora asignada ya no se puede editar.
        AsyncData(:final value)
            when value != null && !SolicitudService.sePuedeEditar(value) =>
          EstadoVacio(
            icono: Icons.lock_outline_rounded,
            titulo: 'Esta solicitud ya no se puede editar',
            mensaje: 'Solo se editan las solicitudes publicadas, antes de '
                'elegir trabajadora.',
            textoBoton: 'Volver a Mis solicitudes',
            onPressed: () => context.go(Rutas.inicioCliente),
          ),
        _ => null,
      };
      if (aviso != null) return Scaffold(body: SafeArea(child: aviso));
      // Mientras el formulario se llena (un instante).
      if (_original == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }

    if (_repitiendo) {
      final cargada = ref.watch(solicitudParaEditarProvider(widget.repetirDe!));
      final aviso = switch (cargada) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final error) => EstadoVacio(
            icono: Icons.wifi_off_rounded,
            titulo: error is AppException
                ? error.mensaje
                : 'No pudimos cargar la solicitud.',
            textoBoton: 'Volver a Mis solicitudes',
            onPressed: () => context.go(Rutas.inicioCliente),
          ),
        AsyncData(:final value) when value == null => EstadoVacio(
            icono: Icons.search_off_rounded,
            titulo: 'No encontramos esta solicitud',
            textoBoton: 'Volver a Mis solicitudes',
            onPressed: () => context.go(Rutas.inicioCliente),
          ),
        _ => null,
      };
      if (aviso != null) return Scaffold(body: SafeArea(child: aviso));
      if (_base == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }

    final estado = ref.watch(publicarSolicitudProvider);
    final zonas = ref.watch(zonasCatalogoProvider);
    final tema = Theme.of(context);

    // Izquierda: fecha, tipo, lugar y detalles para la trabajadora.
    final formulario = _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Fecha y tipo de servicio', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _fechaKey,
            child: _DosColumnas(
              izquierda: _CampoBoton(
                etiqueta: 'Fecha',
                valor: _fecha == null ? 'Elige la fecha' : _fechaCorta(_fecha!),
                icono: Icons.calendar_today_outlined,
                onTap: _elegirFecha,
                errorText: _intentoEnviar && _fecha == null
                    ? 'Elige la fecha del servicio'
                    : (_intentoEnviar &&
                            _inicio != null &&
                            !_inicio!.isAfter(DateTime.now())
                        ? 'La fecha debe ser futura'
                        : null),
              ),
              derecha: _CampoBoton(
                etiqueta: 'Hora de inicio',
                valor: _horaTexto(_hora),
                icono: Icons.schedule,
                onTap: _elegirHora,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Contador(
            etiqueta: 'Horas estimadas',
            valor: _horas,
            minimo: SolicitudService.horasMinimas,
            maximo: SolicitudService.horasMaximas,
            onCambio: (v) => setState(() => _horas = v),
          ),
          const SizedBox(height: 20),
          Text('Tipo de limpieza', style: tema.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tipo in TipoLimpieza.values)
                ChoiceChip(
                  label: Text(tipo.etiqueta),
                  selected: _tipo == tipo,
                  onSelected: (_) => setState(() => _tipo = tipo),
                ),
            ],
          ),
          const Divider(height: 40),
          Text('Lugar', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Corrección de la revisión: la zona se elige en orden
          // Municipio → Parroquia → Urbanización.
          KeyedSubtree(
            key: _zonaKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                zonas.when(
                  data: (lista) => SelectorZona(
                    zonas: lista,
                    valor: _zonaId,
                    onChanged: (id) => setState(() => _zonaId = id),
                    validator: (_) => _zonaId == null ? 'Elige una zona' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Row(
                    children: [
                      const Expanded(child: Text('No pudimos cargar las zonas.')),
                      // H9: el error trae su solución.
                      TextButton(
                        onPressed: () => ref.invalidate(zonasCatalogoProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
                if (_intentoEnviar && _zonaId == null)
                  const _TextoError(
                    texto: 'Elige una zona (municipio, parroquia y urbanización)',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _direccionKey,
            child: TextFormField(
              controller: _direccion,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                helperText: 'Privada hasta que elijas a una trabajadora',
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Escribe la dirección completa'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _DosColumnas(
            izquierda: _Contador(
              etiqueta: 'Habitaciones',
              valor: _habitaciones,
              minimo: 0,
              maximo: 20,
              onCambio: (v) => setState(() => _habitaciones = v),
            ),
            derecha: _Contador(
              etiqueta: 'Baños',
              valor: _banos,
              minimo: 0,
              maximo: 20,
              onCambio: (v) => setState(() => _banos = v),
            ),
          ),
          const Divider(height: 40),
          Text(
            'Detalles para la trabajadora',
            style: tema.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _DosColumnas(
            izquierda: _Opciones<bool>(
              etiqueta: '¿Hay mascotas?',
              opciones: const {false: 'No', true: 'Sí'},
              valor: _mascotas,
              onCambio: (v) => setState(() => _mascotas = v),
            ),
            derecha: KeyedSubtree(
              key: _productosKey,
              child: _Opciones<QuienPoneProductos>(
                etiqueta: '¿Quién pone los productos?',
                opciones: {
                  for (final p in QuienPoneProductos.values) p: p.etiqueta,
                },
                valor: _productos,
                error: _intentoEnviar && _productos == null
                    ? 'Indica quién pone los productos'
                    : null,
                onCambio: (v) => setState(() => _productos = v),
              ),
            ),
          ),
        ],
      ),
    );

    // Campos de pago: van en la caja "Pago", junto al total.
    final campoPago = KeyedSubtree(
      key: _pagoKey,
      child: TextFormField(
        controller: _pago,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Pago ofrecido (USD)',
          prefixText: r'$ ',
        ),
        validator: (_) =>
            _montoPago <= 0 ? 'Escribe cuánto vas a pagar' : null,
      ),
    );

    final campoMetodo = DropdownButtonFormField<MetodoPago>(
      initialValue: _metodo,
      decoration: const InputDecoration(labelText: 'Método de pago'),
      items: [
        for (final m in MetodoPago.values)
          DropdownMenuItem(value: m, child: Text(m.etiqueta)),
      ],
      onChanged: (m) {
        if (m != null) setState(() => _metodo = m);
      },
    );

    final faltantes =
        _intentoEnviar ? _camposFaltantes() : const <({String nombre, GlobalKey key})>[];

    // Derecha arriba: "Así la verán las trabajadoras".
    final vistaPrevia = _VistaPrevia(
      tipo: _tipo,
      fecha: _fecha,
      hora: _hora,
      horas: _horas,
      zona: _nombreZona(zonas),
      habitaciones: _habitaciones,
      banos: _banos,
      errorFecha: _intentoEnviar &&
          (_fecha == null ||
              (_inicio != null && !_inicio!.isAfter(DateTime.now()))),
      errorZona: _intentoEnviar && _zonaId == null,
    );

    // Derecha abajo: pago, total y botón.
    final cajaPago = _CajaPago(
      campoPago: campoPago,
      campoMetodo: campoMetodo,
      pago: _montoPago,
      cargando: estado.isLoading,
      error: estado.hasError ? _mensajeDeError(estado.error!) : null,
      onPublicar: _publicar,
      textoBoton: _editando ? 'Guardar cambios' : 'Publicar solicitud',
      // Figma: "Las postulantes verán los datos nuevos".
      aviso: _editando && (_original?.numPostulantes ?? 0) > 0
          ? 'Las postulantes verán los datos nuevos'
          : null,
      faltantes: faltantes,
      onIrACampo: _irACampo,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(Rutas.inicioCliente),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Mis solicitudes'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _editando
                        ? 'Editar solicitud'
                        : _repitiendo
                            ? 'Repetir solicitud'
                            : 'Publica una solicitud',
                    style: tema.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _repitiendo
                        ? 'Copiamos los datos de tu solicitud anterior. Elige '
                            'la nueva fecha y revisa lo demás; la anterior no '
                            'cambia.'
                        : 'Cuéntales a las trabajadoras qué necesitas. Podrás '
                            'elegir entre quienes se postulen.',
                    style: tema.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // El Form envuelve las dos columnas, porque el pago quedó
                  // en la caja de la derecha y también se valida.
                  Form(
                    key: _formKey,
                    autovalidateMode: _intentoEnviar
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 900) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              formulario,
                              const SizedBox(height: 16),
                              vistaPrevia,
                              const SizedBox(height: 16),
                              cajaPago,
                            ],
                          );
                        }
                        // Feedback del Product Review: las dos columnas al
                        // mismo nivel, sin espacio en blanco.
                        return _FilaMismaAltura(
                          children: [formulario, vistaPrevia, cajaPago],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nombre de la zona elegida, o null si todavía no se eligió o no cargó.
  String? _nombreZona(AsyncValue<List<Zona>> zonas) {
    final lista = switch (zonas) {
      AsyncData(:final value) => value,
      _ => const <Zona>[],
    };
    for (final zona in lista) {
      if (zona.id == _zonaId) return zona.nombre;
    }
    return null;
  }

  String _mensajeDeError(Object error) {
    if (error is AppException) return error.mensaje;
    return 'No pudimos publicar la solicitud. Intenta de nuevo.';
  }
}

// ---------------------------------------------------------------------------
// Vista previa: "Así la verán las trabajadoras"
// ---------------------------------------------------------------------------

class _VistaPrevia extends StatelessWidget {
  const _VistaPrevia({
    required this.tipo,
    required this.fecha,
    required this.hora,
    required this.horas,
    required this.zona,
    required this.habitaciones,
    required this.banos,
    this.errorFecha = false,
    this.errorZona = false,
  });

  final TipoLimpieza tipo;
  /// Null mientras no se elija (HU-44).
  final DateTime? fecha;
  final TimeOfDay hora;
  final int horas;
  final String? zona;
  final int habitaciones;
  final int banos;
  final bool errorFecha;
  final bool errorZona;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return _Tarjeta(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASÍ LA VERÁN LAS TRABAJADORAS',
            style: tema.textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(tipo.etiqueta)),
          ),
          const SizedBox(height: 8),
          Text(
            fecha == null ? 'Fecha por elegir' : _fechaLarga(fecha!),
            style: tema.textTheme.titleLarge?.copyWith(
              color: errorFecha ? AppColors.error : null,
            ),
          ),
          const SizedBox(height: 8),
          _Dato(
            icono: Icons.schedule,
            texto: '${_horaTexto(hora)} · $horas horas',
          ),
          _Dato(
            icono: Icons.place_outlined,
            texto: zona ?? 'Elige una zona',
            colorTexto: errorZona ? AppColors.error : null,
          ),
          _Dato(
            icono: Icons.bed_outlined,
            texto: '$habitaciones habitaciones · $banos baños',
          ),
          const SizedBox(height: 12),
          // Metáfora "llave y candado": la dirección es privada.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colores.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: colores.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La dirección exacta no se muestra hasta que elijas '
                    'a una trabajadora.',
                    style: TextStyle(color: colores.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Caja "Pago": campos de pago, desglose (HU-52), avisos y botón
// ---------------------------------------------------------------------------

class _CajaPago extends StatelessWidget {
  const _CajaPago({
    required this.campoPago,
    required this.campoMetodo,
    required this.pago,
    required this.cargando,
    required this.error,
    required this.onPublicar,
    this.textoBoton = 'Publicar solicitud',
    this.aviso,
    this.faltantes = const [],
    this.onIrACampo,
  });

  final Widget campoPago;
  final Widget campoMetodo;
  final double pago;
  final bool cargando;
  final String? error;
  final VoidCallback onPublicar;
  final String textoBoton;

  /// Aviso ámbar sobre el botón (HU-09: hay postulantes).
  final String? aviso;

  /// Lista interactiva de campos que faltan por completar.
  final List<({String nombre, GlobalKey key})> faltantes;
  final void Function(GlobalKey key)? onIrACampo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return _Tarjeta(
      // spaceBetween: si la caja se estira para igualar al formulario, los
      // campos quedan arriba y el botón abajo.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PAGO',
                style:
                    tema.textTheme.labelMedium?.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 16),
              campoPago,
              const SizedBox(height: 16),
              campoMetodo,
              const Divider(height: 32),
              // HU-52: desglose del costo.
              _FilaMonto(etiqueta: 'La trabajadora recibe', monto: pago),
              _FilaMonto(
                etiqueta: 'Tarifa LimpiaYa (10 %)',
                monto: SolicitudService.tarifa(pago),
              ),
              const SizedBox(height: 4),
              _FilaMonto(
                etiqueta: 'Total a pagar',
                monto: SolicitudService.total(pago),
                fuerte: true,
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colores.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(color: colores.onErrorContainer),
                  ),
                ),
              ],
              if (aviso != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.insigniaAmbarFondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    aviso!,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: AppColors.aviso,
                    ),
                  ),
                ),
              ],
              if (faltantes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.insigniaRojaFondo,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 20,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Faltan datos obligatorios:',
                              style: tema.textTheme.labelMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final f in faltantes)
                            InkWell(
                              onTap: onIrACampo != null
                                  ? () => onIrACampo!(f.key)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        AppColors.error.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      f.nombre,
                                      style:
                                          tema.textTheme.bodySmall?.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: cargando ? null : onPublicar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                child: cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(textoBoton),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fila de dos columnas de la misma altura (pantalla grande)
// ---------------------------------------------------------------------------

/// Recibe tres hijos: [izquierda, derechaArriba, derechaAbajo].
///
/// La izquierda ocupa 3/5 del ancho y la derecha 2/5. Al final, las dos
/// columnas miden lo mismo: si la derecha es más corta, se estira la caja de
/// abajo (la de pago); si es más larga, se estira la izquierda.
class _FilaMismaAltura extends MultiChildRenderObjectWidget {
  const _FilaMismaAltura({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFilaMismaAltura();
}

class _DatosFila extends ContainerBoxParentData<RenderBox> {}

class _RenderFilaMismaAltura extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DatosFila>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DatosFila> {
  static const _espacio = 24.0; // entre la columna izquierda y la derecha
  static const _separacion = 16.0; // entre las dos cajas de la derecha
  static const _fraccionIzquierda = 3 / 5;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DatosFila) child.parentData = _DatosFila();
  }

  @override
  void performLayout() {
    final izquierda = firstChild!;
    final arriba = childAfter(izquierda)!;
    final abajo = childAfter(arriba)!;

    final ancho = constraints.maxWidth;
    final anchoIzquierda = (ancho - _espacio) * _fraccionIzquierda;
    final anchoDerecha = ancho - _espacio - anchoIzquierda;

    // 1) Cada caja con su altura natural.
    izquierda.layout(
      BoxConstraints.tightFor(width: anchoIzquierda),
      parentUsesSize: true,
    );
    arriba.layout(
      BoxConstraints.tightFor(width: anchoDerecha),
      parentUsesSize: true,
    );
    abajo.layout(
      BoxConstraints.tightFor(width: anchoDerecha),
      parentUsesSize: true,
    );

    // 2) La fila mide lo que la columna más alta.
    final altoDerecha =
        arriba.size.height + _separacion + abajo.size.height;
    final alto = math.max(izquierda.size.height, altoDerecha);

    // 3) Se estiran la izquierda y la caja de abajo hasta esa altura.
    izquierda.layout(
      BoxConstraints.tight(Size(anchoIzquierda, alto)),
      parentUsesSize: true,
    );
    abajo.layout(
      BoxConstraints.tight(
        Size(anchoDerecha, alto - arriba.size.height - _separacion),
      ),
      parentUsesSize: true,
    );

    (izquierda.parentData! as _DatosFila).offset = Offset.zero;
    (arriba.parentData! as _DatosFila).offset =
        Offset(anchoIzquierda + _espacio, 0);
    (abajo.parentData! as _DatosFila).offset = Offset(
      anchoIzquierda + _espacio,
      arriba.size.height + _separacion,
    );

    size = constraints.constrain(Size(ancho, alto));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// Piezas pequeñas de la pantalla
// ---------------------------------------------------------------------------

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colores.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colores.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Dos campos lado a lado; en pantallas angostas, uno debajo del otro.
class _DosColumnas extends StatelessWidget {
  const _DosColumnas({required this.izquierda, required this.derecha});
  final Widget izquierda;
  final Widget derecha;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [izquierda, const SizedBox(height: 16), derecha],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: izquierda),
            const SizedBox(width: 16),
            Expanded(child: derecha),
          ],
        );
      },
    );
  }
}

class _CampoBoton extends StatelessWidget {
  const _CampoBoton({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.onTap,
    this.errorText,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          suffixIcon: Icon(icono),
          errorText: errorText,
        ),
        child: Text(valor),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.etiqueta,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.onCambio,
  });

  final String etiqueta;
  final int valor;
  final int minimo;
  final int maximo;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        ),
        IconButton.outlined(
          tooltip: 'Menos',
          onPressed: valor > minimo ? () => onCambio(valor - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Más',
          onPressed: valor < maximo ? () => onCambio(valor + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _Opciones<T> extends StatelessWidget {
  const _Opciones({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.onCambio,
    this.error,
  });

  final String etiqueta;
  final Map<T, String> opciones;
  final T? valor;
  final ValueChanged<T> onCambio;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tema.textTheme.titleSmall?.copyWith(
            color: error != null ? AppColors.error : null,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: error != null ? const EdgeInsets.all(6) : EdgeInsets.zero,
          decoration: error != null
              ? BoxDecoration(
                  color: AppColors.insigniaRojaFondo.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                )
              : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entrada in opciones.entries)
                ChoiceChip(
                  label: Text(entrada.value),
                  selected: valor == entrada.key,
                  onSelected: (_) => onCambio(entrada.key),
                ),
            ],
          ),
        ),
        if (error != null) _TextoError(texto: error!),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, this.colorTexto});
  final IconData icono;
  final String texto;
  final Color? colorTexto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 20, color: colorTexto),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: colorTexto != null
                  ? TextStyle(
                      color: colorTexto,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMonto extends StatelessWidget {
  const _FilaMonto({
    required this.etiqueta,
    required this.monto,
    this.fuerte = false,
  });

  final String etiqueta;
  final double monto;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final estilo = fuerte
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          // H2: se aclara la moneda.
          Text('${_usd(monto)} (USD)', style: estilo),
        ],
      ),
    );
  }
}

class _TextoError extends StatelessWidget {
  const _TextoError({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        texto,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colores.error),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatos en español, sin depender de otras librerías
// ---------------------------------------------------------------------------

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String _fechaLarga(DateTime f) =>
    '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]}';

String _fechaCorta(DateTime f) {
  final dia = f.day.toString().padLeft(2, '0');
  final mes = f.month.toString().padLeft(2, '0');
  return '$dia/$mes/${f.year}';
}

String _horaTexto(TimeOfDay h) {
  final hora12 = h.hourOfPeriod == 0 ? 12 : h.hourOfPeriod;
  final minutos = h.minute.toString().padLeft(2, '0');
  final periodo = h.period == DayPeriod.am ? 'a. m.' : 'p. m.';
  return '$hora12:$minutos $periodo';
}

String _usd(double monto) =>
    '\$${monto.toStringAsFixed(2).replaceAll('.', ',')}';