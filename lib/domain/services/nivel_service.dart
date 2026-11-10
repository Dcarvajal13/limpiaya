import '../entities/postulante.dart';

/// Reglas de HU-61 · Subir de nivel como trabajadora (insignia "Destacada").
///
/// La base calcula la insignia en la vista `nivel_trabajadoras` (migración de
/// HU-61). Aquí están los mismos umbrales para explicarle a la trabajadora
/// cuánto le falta, y el orden de las postulantes.
///
/// Vive en el dominio y no conoce Supabase ni Flutter.
abstract final class NivelService {
  /// c1 · Servicios completados que hacen falta.
  static const minServicios = 10;

  /// c1 y c3 · Promedio mínimo (solo cuentan las reseñas ya visibles).
  static const minPromedio = 4.5;

  /// c1 · Días en los que no puede tener cancelaciones tardías (HU-28).
  static const diasSinCancelaciones = 30;

  static const nombreInsignia = 'Destacada';

  static const explicacion =
      'Las trabajadoras destacadas aparecen primero cuando un cliente ve '
      'sus postulantes.';

  /// c1 · Misma regla que la base.
  static bool cumple({
    required int servicios,
    required double? promedio,
    required int cancelacionesTardias,
  }) =>
      servicios >= minServicios &&
      (promedio ?? 0) >= minPromedio &&
      cancelacionesTardias == 0;

  /// c2 · Las destacadas primero. Entre ellas, y entre las demás, se respeta
  /// el orden en que llegaron (quien se postuló antes, antes).
  static List<Postulante> ordenarPostulantes(List<Postulante> postulantes) => [
        for (final p in postulantes)
          if (p.destacada) p,
        for (final p in postulantes)
          if (!p.destacada) p,
      ];

  /// "7 de 10 servicios completados".
  static String progresoServicios(int servicios) {
    final hechos = servicios > minServicios ? minServicios : servicios;
    return '$hechos de $minServicios servicios completados';
  }

  /// "Promedio de 4,6 (mínimo 4,5)" o "Aún sin promedio (mínimo 4,5)".
  static String progresoPromedio(double? promedio) {
    const minimo = '(mínimo 4,5)';
    if (promedio == null) return 'Aún sin promedio $minimo';
    final valor = promedio.toStringAsFixed(1).replaceAll('.', ',');
    return 'Promedio de $valor $minimo';
  }

  /// "Sin cancelaciones tardías en 30 días" o
  /// "1 cancelación tardía en los últimos 30 días".
  static String progresoCancelaciones(int cancelaciones) {
    if (cancelaciones == 0) {
      return 'Sin cancelaciones tardías en $diasSinCancelaciones días';
    }
    final texto = cancelaciones == 1
        ? '1 cancelación tardía'
        : '$cancelaciones cancelaciones tardías';
    return '$texto en los últimos $diasSinCancelaciones días';
  }
}
