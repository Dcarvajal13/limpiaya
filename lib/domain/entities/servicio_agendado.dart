import '../services/chat_service.dart';
import 'estado_solicitud.dart';
import 'metodo_pago.dart';
import 'quien_pone_productos.dart';
import 'tipo_limpieza.dart';

/// Un servicio ya asignado, completado o cancelado (HU-16).
///
/// Es la vista de una solicitud desde el lado de quien la está viviendo:
/// la trabajadora asignada o el cliente dueño. Incluye la dirección exacta
/// porque RLS solo deja leerla a esas dos personas.
class ServicioAgendado {
  const ServicioAgendado({
    required this.id,
    required this.estado,
    required this.tipo,
    required this.zona,
    required this.inicio,
    required this.horasEstimadas,
    required this.pagoOfrecido,
    required this.metodoPago,
    required this.soyCliente,
    this.habitaciones = 1,
    this.banos = 1,
    this.tieneMascotas = false,
    this.productosPor,
    this.direccion,
    this.puntoReferencia,
    this.notas,
    this.motivoCancelacion,
    this.completadaEn,
    this.canceladaEn,
    this.contraparteId,
    this.contraparteNombre,
    this.contraparteFotoUrl,
    this.contrapartePromedio,
    this.yaCalifique = false,
  });

  final String id;
  final EstadoSolicitud estado;
  final TipoLimpieza tipo;

  /// Nombre de la zona del servicio (ej. "Los Palos Grandes").
  final String zona;

  final DateTime inicio;
  final double horasEstimadas;
  final double pagoOfrecido;
  final MetodoPago metodoPago;

  final int habitaciones;
  final int banos;
  final bool tieneMascotas;
  final QuienPoneProductos? productosPor;

  /// Dirección exacta. Solo la ven el cliente dueño y la trabajadora asignada.
  final String? direccion;
  final String? puntoReferencia;
  final String? notas;

  final String? motivoCancelacion;
  final DateTime? completadaEn;
  final DateTime? canceladaEn;

  /// La otra parte: la trabajadora si quien mira es el cliente, o el cliente
  /// si quien mira es la trabajadora.
  final String? contraparteId;
  final String? contraparteNombre;
  final String? contraparteFotoUrl;
  final double? contrapartePromedio;

  /// Si quien mira es el cliente dueño del servicio.
  final bool soyCliente;

  /// Si esta persona ya calificó el servicio (HU-29).
  final bool yaCalifique;

  /// HU-16 c1: "Próximos" son los asignados; se ordenan del más cercano
  /// al más lejano.
  bool get esProximo => estado == EstadoSolicitud.asignada;

  /// HU-16 c3: "Pasados" son los completados y los cancelados.
  bool get esPasado =>
      estado == EstadoSolicitud.completada ||
      estado == EstadoSolicitud.cancelada;

  /// HU-16 c4: un servicio completado sin mi calificación ofrece "Calificar".
  bool get puedeCalificar =>
      estado == EstadoSolicitud.completada && !yaCalifique;

  /// HU-38 · Si la otra parte y yo todavía podemos escribirnos.
  bool get chatAbierto => ChatService.chatAbierto(
        estado,
        completadaEn: completadaEn,
        canceladaEn: canceladaEn,
      );

  /// HU-17: el cliente puede marcarlo completado desde que empezó.
  bool get puedeCompletar =>
      soyCliente &&
      estado == EstadoSolicitud.asignada &&
      !inicio.isAfter(DateTime.now());
}
