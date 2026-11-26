import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../domain/entities/cuenta_usuario.dart';
import '../../../domain/services/admin_service.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_estado.dart';

/// HU-34 · Suspender o reactivar cuentas de clientes y trabajadoras.
class PanelCuentasAdmin extends ConsumerStatefulWidget {
  const PanelCuentasAdmin({super.key});

  @override
  ConsumerState<PanelCuentasAdmin> createState() => _PanelCuentasAdminState();
}

class _PanelCuentasAdminState extends ConsumerState<PanelCuentasAdmin> {
  final _busqueda = TextEditingController();
  bool _soloSuspendidas = false;
  bool _guardando = false;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _suspender(CuentaUsuario cuenta) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => _DialogoSuspension(cuenta: cuenta),
    );
    if (motivo == null) return;
    await _ejecutar(
      () => ref.read(adminServiceProvider).suspenderCuenta(cuenta.id, motivo),
      'Cuenta de ${cuenta.nombre} suspendida.',
    );
  }

  Future<void> _reactivar(CuentaUsuario cuenta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reactivar esta cuenta?'),
        content: Text(
          '${cuenta.nombre} podrá volver a iniciar sesión y usar LimpiaYa.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await _ejecutar(
      () => ref.read(adminServiceProvider).reactivarCuenta(cuenta.id),
      'Cuenta de ${cuenta.nombre} reactivada.',
    );
  }

  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    final mensajes = ScaffoldMessenger.of(context);
    setState(() => _guardando = true);
    try {
      await accion();
      ref.invalidate(cuentasAdminProvider);
      mensajes.showSnackBar(SnackBar(content: Text(exito)));
    } on AppException catch (e) {
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuentasAsync = ref.watch(cuentasAdminProvider);

    return cuentasAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EstadoVacio(
        icono: Icons.error_outline_rounded,
        titulo: 'No pudimos cargar las cuentas',
        mensaje: error is AppException ? error.mensaje : null,
        textoBoton: 'Intentar de nuevo',
        onPressed: () => ref.invalidate(cuentasAdminProvider),
      ),
      data: (cuentas) {
        final filtradas = AdminService.filtrarCuentas(
          cuentas,
          busqueda: _busqueda.text,
          soloSuspendidas: _soloSuspendidas,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _busqueda,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre…',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Solo suspendidas'),
                  selected: _soloSuspendidas,
                  onSelected: (v) => setState(() => _soloSuspendidas = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (filtradas.isEmpty)
              const EstadoVacio(
                icono: Icons.manage_accounts_outlined,
                titulo: 'Sin cuentas para mostrar',
                mensaje: 'Prueba quitando el filtro o buscando otro nombre.',
              )
            else
              for (final cuenta in filtradas) ...[
                _TarjetaCuenta(
                  cuenta: cuenta,
                  guardando: _guardando,
                  onSuspender: () => _suspender(cuenta),
                  onReactivar: () => _reactivar(cuenta),
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _TarjetaCuenta extends StatelessWidget {
  const _TarjetaCuenta({
    required this.cuenta,
    required this.guardando,
    required this.onSuspender,
    required this.onReactivar,
  });

  final CuentaUsuario cuenta;
  final bool guardando;
  final VoidCallback onSuspender;
  final VoidCallback onReactivar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarUsuario(
                  nombre: cuenta.nombre,
                  fotoUrl: cuenta.fotoUrl,
                  tamano: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cuenta.nombre, style: textos.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          InsigniaEstado(
                            cuenta.esCliente ? 'Cliente' : 'Trabajadora',
                            tono: TonoInsignia.azul,
                          ),
                          if (cuenta.suspendido)
                            const InsigniaEstado(
                              'Suspendida',
                              tono: TonoInsignia.rojo,
                            )
                          else if (!cuenta.activo)
                            const InsigniaEstado(
                              'Desactivada',
                              tono: TonoInsignia.gris,
                            )
                          else
                            const InsigniaEstado(
                              'Activa',
                              tono: TonoInsignia.verde,
                            ),
                          if (cuenta.serviciosActivos > 0)
                            InsigniaEstado(
                              '${cuenta.serviciosActivos} activo(s)',
                              tono: TonoInsignia.ambar,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (cuenta.suspendido)
                  FilledButton.icon(
                    onPressed: guardando ? null : onReactivar,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: const Text('Reactivar'),
                  )
                else if (cuenta.activo)
                  OutlinedButton.icon(
                    onPressed: guardando ? null : onSuspender,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.block_rounded, size: 18),
                    label: const Text('Suspender'),
                  ),
              ],
            ),
            if (cuenta.suspendido &&
                (cuenta.motivoSuspension ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.insigniaRojaFondo,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Motivo: ${cuenta.motivoSuspension}'
                  '${cuenta.suspendidoEn != null ? ' · ${Formato.diaMesCorto(cuenta.suspendidoEn!)}' : ''}',
                  style: textos.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogoSuspension extends StatefulWidget {
  const _DialogoSuspension({required this.cuenta});

  final CuentaUsuario cuenta;

  @override
  State<_DialogoSuspension> createState() => _DialogoSuspensionState();
}

class _DialogoSuspensionState extends State<_DialogoSuspension> {
  final _motivo = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _enviar() {
    final error = AdminService.validarMotivoSuspension(_motivo.text);
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
      title: Text('Suspender a ${widget.cuenta.nombre}'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.insigniaAmbarFondo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Efecto automático: se cancelarán sus solicitudes publicadas y '
                'servicios asignados (avisando a la contraparte) y se retirarán '
                'sus postulaciones pendientes.',
                style: textos.bodySmall?.copyWith(color: AppColors.aviso),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motivo,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Motivo de la suspensión',
                hintText: 'Ej.: incumplimiento reiterado de servicios…',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: AppTheme.botonPeligro,
          onPressed: _enviar,
          child: const Text('Suspender cuenta'),
        ),
      ],
    );
  }
}
