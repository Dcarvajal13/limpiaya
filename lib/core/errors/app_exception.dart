/// Error con un mensaje listo para mostrarle al usuario, en español.
///
/// La capa data convierte los errores de Supabase en AppException.
/// Así las pantallas solo muestran `error.mensaje` y no necesitan
/// saber nada de Supabase.
class AppException implements Exception {
  const AppException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// HU-40 c2 · Quiso entrar sin haber confirmado su correo. Lleva el correo
/// para poder reenviarle el enlace.
class CorreoSinVerificarException extends AppException {
  const CorreoSinVerificarException(this.email)
      : super('Aún no verificas tu correo');

  final String email;
}
