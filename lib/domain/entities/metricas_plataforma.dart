/// HU-36 · Métricas mensuales de la plataforma (hipótesis del MVP).
class MetricasPlataforma {
  const MetricasPlataforma({
    required this.mes,
    required this.totalSolicitudes,
    required this.solicitudesConPostulacion,
    required this.pctConPostulacion,
    required this.solicitudesAsignadas,
    required this.solicitudesCompletadas,
    required this.solicitudesCanceladas,
    required this.pctCompletado,
    required this.clientesNuevos,
    required this.trabajadorasNuevas,
    required this.trabajadorasVerificadas,
    required this.volumenUsd,
  });

  final DateTime mes;
  final int totalSolicitudes;
  final int solicitudesConPostulacion;
  final double pctConPostulacion;
  final int solicitudesAsignadas;
  final int solicitudesCompletadas;
  final int solicitudesCanceladas;
  final double pctCompletado;
  final int clientesNuevos;
  final int trabajadorasNuevas;
  final int trabajadorasVerificadas;
  final double volumenUsd;

  int get usuariosNuevos => clientesNuevos + trabajadorasNuevas;
}
