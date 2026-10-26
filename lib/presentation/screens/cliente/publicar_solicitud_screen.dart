import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/rutas.dart';
import '../../../domain/entities/metodo_pago.dart';
import '../../../domain/entities/nueva_solicitud.dart';
import '../../../domain/entities/quien_pone_productos.dart';
import '../../../domain/entities/tipo_limpieza.dart';
import '../../../domain/entities/zona.dart';
import '../../../domain/services/solicitud_service.dart';
import '../../providers/publicar_solicitud_provider.dart';

/// HU-07 · Publicar una solicitud de limpieza (incluye HU-43 y HU-52).
class PublicarSolicitudScreen extends ConsumerStatefulWidget {
  const PublicarSolicitudScreen({super.key});

  @override
  ConsumerState<PublicarSolicitudScreen> createState() =>
      _PublicarSolicitudScreenState();
}

class _PublicarSolicitudScreenState
    extends ConsumerState<PublicarSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccion = TextEditingController();
  final _pago = TextEditingController(text: '30');

  late DateTime _fecha;
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

  @override
  void initState() {
    super.initState();
    final manana = DateTime.now().add(const Duration(days: 1));
    _fecha = DateTime(manana.year, manana.month, manana.day);
    _direccion.addListener(() => setState(() {}));
    _pago.addListener(() => setState(() {}));

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
    _direccion.dispose();
    _pago.dispose();
    super.dispose();
  }

  DateTime get _inicio =>
      DateTime(_fecha.year, _fecha.month, _fecha.day, _hora.hour, _hora.minute);

  double get _montoPago =>
      double.tryParse(_pago.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      // H5: los días pasados no se pueden elegir.
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 90)),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _elegirHora() async {
    final elegida = await showTimePicker(context: context, initialTime: _hora);
    if (elegida != null) setState(() => _hora = elegida);
  }

  Future<void> _publicar() async {
    setState(() => _intentoEnviar = true);
    final valido = _formKey.currentState!.validate();
    if (!valido || _zonaId == null || _productos == null) return;

    final solicitud = NuevaSolicitud(
      tipo: _tipo,
      zonaId: _zonaId!,
      direccion: _direccion.text.trim(),
      inicio: _inicio,
      horasEstimadas: _horas.toDouble(),
      pagoOfrecido: _montoPago,
      metodoPago: _metodo,
      habitaciones: _habitaciones,
      banos: _banos,
      tieneMascotas: _mascotas,
      productosPor: _productos,
    );

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
    final estado = ref.watch(publicarSolicitudProvider);
    final zonas = ref.watch(zonasCatalogoProvider);
    final tema = Theme.of(context);

    final formulario = _Tarjeta(
      child: Form(
        key: _formKey,
        autovalidateMode: _intentoEnviar
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Fecha y tipo de servicio', style: tema.textTheme.titleLarge),
            const SizedBox(height: 16),
            _DosColumnas(
              izquierda: _CampoBoton(
                etiqueta: 'Fecha',
                valor: _fechaCorta(_fecha),
                icono: Icons.calendar_today_outlined,
                onTap: _elegirFecha,
              ),
              derecha: _CampoBoton(
                etiqueta: 'Hora de inicio',
                valor: _horaTexto(_hora),
                icono: Icons.schedule,
                onTap: _elegirHora,
              ),
            ),
            if (_intentoEnviar && !_inicio.isAfter(DateTime.now()))
              const _TextoError(texto: 'La fecha debe ser futura'),
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
            _DosColumnas(
              izquierda: zonas.when(
                data: (lista) => _SelectorZona(
                  zonas: lista,
                  valor: _zonaId,
                  mostrarError: _intentoEnviar && _zonaId == null,
                  onCambio: (id) => setState(() => _zonaId = id),
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
              derecha: TextFormField(
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
              derecha: _Opciones<QuienPoneProductos>(
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
            const SizedBox(height: 16),
            _DosColumnas(
              izquierda: TextFormField(
                controller: _pago,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
              derecha: DropdownButtonFormField<MetodoPago>(
                initialValue: _metodo,
                decoration: const InputDecoration(labelText: 'Método de pago'),
                items: [
                  for (final m in MetodoPago.values)
                    DropdownMenuItem(value: m, child: Text(m.etiqueta)),
                ],
                onChanged: (m) {
                  if (m != null) setState(() => _metodo = m);
                },
              ),
            ),
          ],
        ),
      ),
    );

    final vistaPrevia = _VistaPrevia(
      tipo: _tipo,
      fecha: _fecha,
      hora: _hora,
      horas: _horas,
      zona: _nombreZona(zonas),
      habitaciones: _habitaciones,
      banos: _banos,
      pago: _montoPago,
      cargando: estado.isLoading,
      error: estado.hasError ? _mensajeDeError(estado.error!) : null,
      onPublicar: _publicar,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    'Publica una solicitud',
                    style: tema.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuéntales a las trabajadoras qué necesitas. Podrás '
                    'elegir entre quienes se postulen.',
                    style: tema.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            formulario,
                            const SizedBox(height: 16),
                            vistaPrevia,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: formulario),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: vistaPrevia),
                        ],
                      );
                    },
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
    required this.pago,
    required this.cargando,
    required this.error,
    required this.onPublicar,
  });

  final TipoLimpieza tipo;
  final DateTime fecha;
  final TimeOfDay hora;
  final int horas;
  final String? zona;
  final int habitaciones;
  final int banos;
  final double pago;
  final bool cargando;
  final String? error;
  final VoidCallback onPublicar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;

    return _Tarjeta(
      child: Column(
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
          Text(_fechaLarga(fecha), style: tema.textTheme.titleLarge),
          const SizedBox(height: 8),
          _Dato(
            icono: Icons.schedule,
            texto: '${_horaTexto(hora)} · $horas horas',
          ),
          _Dato(icono: Icons.place_outlined, texto: zona ?? 'Elige una zona'),
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
                : const Text('Publicar solicitud'),
          ),
        ],
      ),
    );
  }
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
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          suffixIcon: Icon(icono),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final entrada in opciones.entries)
              ChoiceChip(
                label: Text(entrada.value),
                selected: valor == entrada.key,
                onSelected: (_) => onCambio(entrada.key),
              ),
          ],
        ),
        if (error != null) _TextoError(texto: error!),
      ],
    );
  }
}

class _SelectorZona extends StatelessWidget {
  const _SelectorZona({
    required this.zonas,
    required this.valor,
    required this.mostrarError,
    required this.onCambio,
  });

  final List<Zona> zonas;
  final int? valor;
  final bool mostrarError;
  final ValueChanged<int?> onCambio;

  @override
  Widget build(BuildContext context) {
    final existe = zonas.any((z) => z.id == valor);
    return DropdownButtonFormField<int>(
      // La clave hace que el selector muestre la zona precargada (HU-05 c2).
      key: ValueKey(existe ? valor : null),
      initialValue: existe ? valor : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Zona',
        errorText: mostrarError ? 'Elige una zona' : null,
      ),
      items: [
        for (final zona in zonas)
          DropdownMenuItem(value: zona.id, child: Text(zona.nombre)),
      ],
      onChanged: onCambio,
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
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