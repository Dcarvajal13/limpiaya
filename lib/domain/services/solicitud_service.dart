import '../../core/errors/app_exception.dart';
import '../entities/nueva_solicitud.dart';
import '../repositories/solicitud_repository.dart';

/// Reglas de negocio de HU-07 · Publicar una solicitud de limpieza.
class SolicitudService {
  SolicitudService(this._repositorio, {DateTime Function()? ahora})
      : _ahora = ahora ?? DateTime.now;

  final SolicitudRepository _repositorio;

  /// Se puede reemplazar en las pruebas para fijar "ahora".
  final DateTime Function() _ahora;

  /// Tarifa de servicio de LimpiaYa (HU-52).
  static const porcentajeTarifa = 0.10;
  static const horasMinimas = 2;
  static const horasMaximas = 10;

  /// Tarifa redondeada a centavos.
  static double tarifa(double pago) =>
      (pago * porcentajeTarifa * 100).roundToDouble() / 100;

  /// Lo que paga el cliente en total.
  static double total(double pago) => pago + tarifa(pago);

  /// Valida la solicitud y la publica. Devuelve el id de la solicitud.
  Future<String> publicar(NuevaSolicitud solicitud) async {
    if (!solicitud.inicio.isAfter(_ahora())) {
      throw const AppException('La fecha debe ser futura'); // HU-07 c2
    }
    if (solicitud.pagoOfrecido <= 0) {
      throw const AppException('Escribe cuánto vas a pagar'); // HU-07 c3
    }
    if (solicitud.horasEstimadas < horasMinimas ||
        solicitud.horasEstimadas > horasMaximas) {
      throw const AppException('Las horas deben estar entre 2 y 10');
    }
    if (solicitud.direccion.trim().length < 5) {
      throw const AppException('Escribe la dirección completa');
    }
    if (solicitud.productosPor == null) {
      throw const AppException('Indica quién pone los productos'); // HU-43 c2
    }
    if (solicitud.habitaciones < 0 || solicitud.banos < 0) {
      throw const AppException('Revisa las habitaciones y los baños');
    }
    return _repositorio.publicar(solicitud);
  }
}