/// HU-19 · Recuperar contraseña: cómo sabe la app que llegó desde el enlace
/// del correo.
///
/// El enlace de Supabase vuelve a la app con `?recuperar=1` (y el código que
/// Supabase cambia por una sesión al arrancar). Mientras esa marca esté en la
/// dirección y no se haya guardado la contraseña nueva, el router manda a
/// "Nueva contraseña" en vez del inicio.
abstract final class Recuperacion {
  static const parametro = 'recuperar';

  /// Si la app se abrió desde el enlace de recuperación.
  static bool vieneDelEnlace(Uri direccion) =>
      direccion.queryParameters[parametro] == '1';

  /// Dirección a la que vuelve el enlace del correo: la misma app, en la
  /// raíz, con la marca. Ej.: http://localhost:54116/?recuperar=1
  static String enlaceDeRegreso([Uri? base]) {
    final actual = base ?? Uri.base;
    return Uri(
      scheme: actual.scheme,
      host: actual.host,
      port: actual.hasPort ? actual.port : null,
      path: '/',
      queryParameters: {parametro: '1'},
    ).toString();
  }

  /// Si Supabase devolvió un error en el enlace (por ejemplo, porque ya se
  /// usó o venció), el mensaje para mostrar en el login. Si no, null.
  static String? errorDelEnlace(Uri direccion) {
    final codigo = direccion.queryParameters['error_code'];
    if (codigo == null) return null;
    if (codigo == 'otp_expired') {
      return 'El enlace del correo venció o ya se usó. Pide uno nuevo con '
          '"¿Olvidaste tu contraseña?" y abre solo el último correo.';
    }
    return 'No pudimos abrir el enlace del correo. Pide uno nuevo con '
        '"¿Olvidaste tu contraseña?".';
  }
}
