import 'estado_solicitud.dart';
import 'tipo_limpieza.dart';

/// Un chat en la lista "Mensajes" (HU-38).
///
/// Junta lo que la persona necesita para decidir si abrirlo: con quién es,
/// cómo va el servicio, lo último que se dijeron y cuántos mensajes no ha
/// leído.
class Conversacion {
  const Conversacion({
    required this.solicitudId,
    required this.contraparteId,
    required this.contraparteNombre,
    required this.tipo,
    required this.inicio,
    required this.estado,
    this.contraparteFotoUrl,
    this.ultimoMensaje,
    this.ultimoEn,
    this.ultimoEsMio = false,
    this.noLeidos = 0,
  });

  final String solicitudId;

  /// La otra parte del servicio: la trabajadora o el cliente.
  final String contraparteId;
  final String contraparteNombre;
  final String? contraparteFotoUrl;

  final TipoLimpieza tipo;
  final DateTime inicio;
  final EstadoSolicitud estado;

  final String? ultimoMensaje;
  final DateTime? ultimoEn;

  /// Si el último mensaje lo escribió quien está mirando (se muestra "Tú: ").
  final bool ultimoEsMio;

  /// Mensajes de la otra parte que todavía no se leyeron.
  final int noLeidos;

  bool get tieneMensajes => ultimoEn != null;
}
