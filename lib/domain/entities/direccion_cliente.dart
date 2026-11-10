/// Zona y dirección que el cliente guardó en su perfil (HU-05).
class DireccionCliente {
  const DireccionCliente({this.zonaId, this.direccion, this.puntoReferencia});

  final int? zonaId;
  final String? direccion;
  final String? puntoReferencia;
}