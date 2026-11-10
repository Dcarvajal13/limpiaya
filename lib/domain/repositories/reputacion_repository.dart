/// Contrato de reputación: promedio de estrellas de quien inició sesión.
///
/// La implementación con Supabase está en
/// data/repositories/supabase_reputacion_repository.dart y lee la vista
/// `reputacion` (solo cuenta las reseñas ya visibles, HU-29 c4).
abstract interface class ReputacionRepository {
  /// Promedio de 1 a 5 (por ejemplo 4.9), o null si aún no tiene reseñas.
  /// Lo muestra la insignia "Identidad verificada · ★ 4,9" (HU-11).
  Future<double?> miPromedio();
}
