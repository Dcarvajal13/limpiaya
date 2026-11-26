/// HU-35 · Una reseña reportada en la cola de moderación del administrador.
class ResenaReportada {
  const ResenaReportada({
    required this.reporteId,
    required this.calificacionId,
    required this.estrellas,
    required this.autorNombre,
    required this.destinatarioNombre,
    required this.reportadoPorNombre,
    required this.motivoReporte,
    required this.estado,
    required this.creadoEn,
    this.comentario,
    this.notaAdmin,
  });

  final String reporteId;
  final String calificacionId;
  final int estrellas;
  final String? comentario;
  final String autorNombre;
  final String destinatarioNombre;
  final String reportadoPorNombre;
  final String motivoReporte;
  final String estado;
  final String? notaAdmin;
  final DateTime creadoEn;
}
