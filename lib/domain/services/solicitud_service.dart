import '../../core/errors/app_exception.dart';
import '../entities/estado_solicitud.dart';
import '../entities/nueva_solicitud.dart';
import '../entities/solicitud.dart';
import '../repositories/solicitud_repository.dart';

/// Reglas de negocio de HU-07 · Publicar una solicitud de limpieza y
/// HU-09 · Editar una solicitud publicada y
/// HU-10 · Cancelar una solicitud sin asignar.
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
    _validar(solicitud);
    return _repositorio.publicar(solicitud);
  }

  /// Reglas comunes a publicar (HU-07) y editar (HU-09).
  void _validar(NuevaSolicitud solicitud) {
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
  }

  /// Motivos que se ofrecen al cancelar (Figma, modal "Cancelar servicio").
  static const motivosCancelacion = [
    'Cambio de planes',
    'Ya no necesito el servicio',
    'Otro',
  ];

  /// HU-10 · Solo se cancela una solicitud Publicada (sin trabajadora).
  static bool sePuedeCancelar(Solicitud solicitud) =>
      solicitud.estado == EstadoSolicitud.publicada;

  Future<void> cancelar(Solicitud solicitud, {String? motivo}) {
    if (!sePuedeCancelar(solicitud)) {
      throw const AppException('Solo puedes cancelar solicitudes publicadas');
    }
    return _repositorio.cancelar(solicitud.id, motivo: motivo);
  }

  /// HU-09 c2 · Solo se edita mientras está Publicada (sin trabajadora).
  static bool sePuedeEditar(Solicitud solicitud) =>
      solicitud.estado == EstadoSolicitud.publicada;

  /// HU-09 c3 · ¿Cambió la fecha, la hora o el pago? Si la solicitud tiene
  /// postulantes, la app pide confirmar antes de guardar.
  static bool cambiaFechaHoraOPago(Solicitud original, NuevaSolicitud nueva) =>
      !original.inicio.isAtSameMomentAs(nueva.inicio) ||
      original.pagoOfrecido != nueva.pagoOfrecido;

  /// HU-09 · Valida y guarda los cambios (c1).
  Future<void> editar(Solicitud original, NuevaSolicitud nueva) async {
    if (!sePuedeEditar(original)) {
      throw const AppException(
        'Esta solicitud ya no se puede editar porque dejó de estar publicada.',
      );
    }
    _validar(nueva);
    await _repositorio.editar(original.id, nueva);
  }
}
