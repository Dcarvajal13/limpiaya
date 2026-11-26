import 'rol_usuario.dart';

/// HU-34 · Cuenta de cliente o trabajadora vista desde el panel de admin.
class CuentaUsuario {
  const CuentaUsuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.activo,
    required this.suspendido,
    required this.serviciosActivos,
    required this.creadoEn,
    this.fotoUrl,
    this.motivoSuspension,
    this.suspendidoEn,
    this.verificacion,
  });

  final String id;
  final String nombre;
  final RolUsuario rol;
  final String? fotoUrl;
  final bool activo;
  final bool suspendido;
  final String? motivoSuspension;
  final DateTime? suspendidoEn;
  final String? verificacion;
  final int serviciosActivos;
  final DateTime creadoEn;

  bool get esCliente => rol == RolUsuario.cliente;
}
