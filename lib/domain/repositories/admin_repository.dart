import '../entities/cuenta_usuario.dart';
import '../entities/metricas_plataforma.dart';
import '../entities/resena_reportada.dart';

/// Contrato del dominio para HU-34 (cuentas), HU-35 (moderación) y HU-36 (métricas).
abstract interface class AdminRepository {
  /// HU-34 · Lista todas las cuentas de clientes y trabajadoras.
  Future<List<CuentaUsuario>> listarCuentas();

  /// HU-34 · Suspende una cuenta con motivo obligatorio, cancelando sus
  /// solicitudes/servicios activos.
  Future<void> suspenderCuenta(String usuarioId, String motivo);

  /// HU-34 · Reactiva una cuenta suspendida.
  Future<void> reactivarCuenta(String usuarioId);

  /// HU-35 · Cola de reseñas reportadas pendientes de moderación.
  Future<List<ResenaReportada>> listarResenasReportadas();

  /// HU-35 · Oculta una reseña reportada (desaparece del perfil y promedio).
  Future<void> ocultarResena(String reporteId, {String? nota});

  /// HU-35 · Desestima el reporte y mantiene la reseña visible.
  Future<void> mantenerResena(String reporteId, {String? nota});

  /// Reporta una reseña para que entre a la cola de moderación (soporte HU-35).
  Future<void> reportarResena(String calificacionId, String motivo);

  /// HU-36 · Métricas de la plataforma para el mes indicado.
  Future<MetricasPlataforma> metricas(DateTime mes);
}
