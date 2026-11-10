import 'zona.dart';

/// Perfil del cliente (HU-05): su zona y su dirección de referencia.
///
/// Es una entidad del dominio: no sabe nada de Supabase.
class PerfilCliente {
  const PerfilCliente({
    this.zona,
    this.direccion,
    this.puntoReferencia,
  });

  /// Zona elegida, o null si todavía no la completó.
  final Zona? zona;

  /// Dirección exacta (privada: nunca la ven las trabajadoras).
  final String? direccion;

  /// Punto de referencia opcional ("al lado del farmatodo").
  final String? puntoReferencia;

  /// Mismo cálculo que `perfil_completo` en `mi_sesion()` para el cliente:
  /// tener zona y dirección.
  bool get completo =>
      zona != null && (direccion ?? '').trim().isNotEmpty;
}
