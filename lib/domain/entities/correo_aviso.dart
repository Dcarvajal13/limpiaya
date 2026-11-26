/// HU-49 · Un aviso por correo electrónico registrado en `cola_correos`.
enum TipoCorreoAviso {
  postulacion('Postulación', 'Cuando una trabajadora se postula a tu solicitud'),
  eleccion('Elección', 'Cuando el cliente te elige para un servicio'),
  recordatorio24h(
    'Recordatorio 24 h',
    'Un día antes de que empiece tu servicio agendado',
  ),
  cancelacion('Cancelación', 'Si se cancela una solicitud o servicio');

  const TipoCorreoAviso(this.etiqueta, this.descripcion);
  final String etiqueta;
  final String descripcion;

  static TipoCorreoAviso desdeTexto(String? valor) => switch (valor) {
        'postulacion' => TipoCorreoAviso.postulacion,
        'eleccion' => TipoCorreoAviso.eleccion,
        'recordatorio_24h' => TipoCorreoAviso.recordatorio24h,
        'cancelacion' => TipoCorreoAviso.cancelacion,
        _ => TipoCorreoAviso.postulacion,
      };
}

enum EstadoCorreoAviso {
  pendiente('Pendiente'),
  enviado('Enviado'),
  cancelado('Cancelado'),
  error('Con error');

  const EstadoCorreoAviso(this.etiqueta);
  final String etiqueta;

  static EstadoCorreoAviso desdeTexto(String? valor) => switch (valor) {
        'enviado' => EstadoCorreoAviso.enviado,
        'cancelado' => EstadoCorreoAviso.cancelado,
        'error' => EstadoCorreoAviso.error,
        _ => EstadoCorreoAviso.pendiente,
      };
}

class CorreoAviso {
  const CorreoAviso({
    required this.id,
    required this.tipo,
    required this.asunto,
    required this.cuerpo,
    required this.estado,
    required this.programadoPara,
    required this.creadoEn,
    this.enviadoEn,
  });

  final String id;
  final TipoCorreoAviso tipo;
  final String asunto;
  final String cuerpo;
  final EstadoCorreoAviso estado;
  final DateTime programadoPara;
  final DateTime? enviadoEn;
  final DateTime creadoEn;
}
