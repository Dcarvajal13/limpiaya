import '../entities/cuenta_usuario.dart';
import '../entities/metricas_plataforma.dart';
import '../repositories/admin_repository.dart';

/// Reglas de dominio para administración: HU-34, HU-35 y HU-36.
class AdminService {
  const AdminService(this._repo);

  final AdminRepository _repo;

  static const errorMotivoSuspension = 'Indica el motivo de la suspensión';
  static const errorMotivoReporte = 'Indica el motivo del reporte';

  /// Valida el motivo antes de suspender una cuenta (HU-34).
  static String? validarMotivoSuspension(String texto) {
    if (texto.trim().isEmpty) return errorMotivoSuspension;
    return null;
  }

  /// Valida el motivo antes de reportar una reseña (HU-35).
  static String? validarMotivoReporte(String texto) {
    if (texto.trim().isEmpty) return errorMotivoReporte;
    return null;
  }

  /// Filtra cuentas por búsqueda de nombre y estado (HU-34).
  static List<CuentaUsuario> filtrarCuentas(
    List<CuentaUsuario> cuentas, {
    String busqueda = '',
    bool soloSuspendidas = false,
  }) {
    final q = busqueda.trim().toLowerCase();
    return cuentas.where((c) {
      if (soloSuspendidas && !c.suspendido) return false;
      if (q.isNotEmpty && !c.nombre.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  /// Calcula un porcentaje seguro (0..100) evitando división entre cero (HU-36).
  static double porcentaje(int parte, int total) {
    if (total <= 0) return 0;
    return double.parse(((parte * 100.0) / total).toStringAsFixed(1));
  }

  /// Resumen textual de la hipótesis del MVP para el mes (HU-36).
  static String resumenHipotesis(MetricasPlataforma m) {
    if (m.totalSolicitudes == 0) {
      return 'Aún no hay solicitudes registradas en este mes.';
    }
    if (m.pctConPostulacion >= 70 && m.pctCompletado >= 50) {
      return 'Tracción saludable: alta tasa de postulación y cierre de servicios.';
    }
    if (m.pctConPostulacion < 50) {
      return 'Oportunidad: menos del 50 % de solicitudes reciben postulaciones.';
    }
    return 'En progreso: hay postulaciones activas; conviene monitorear el cierre.';
  }

  Future<void> suspenderCuenta(String usuarioId, String motivo) {
    final error = validarMotivoSuspension(motivo);
    if (error != null) throw ArgumentError(error);
    return _repo.suspenderCuenta(usuarioId, motivo.trim());
  }

  Future<void> reactivarCuenta(String usuarioId) =>
      _repo.reactivarCuenta(usuarioId);

  Future<void> ocultarResena(String reporteId, {String? nota}) =>
      _repo.ocultarResena(reporteId, nota: nota?.trim());

  Future<void> mantenerResena(String reporteId, {String? nota}) =>
      _repo.mantenerResena(reporteId, nota: nota?.trim());

  Future<void> reportarResena(String calificacionId, String motivo) {
    final error = validarMotivoReporte(motivo);
    if (error != null) throw ArgumentError(error);
    return _repo.reportarResena(calificacionId, motivo.trim());
  }
}
