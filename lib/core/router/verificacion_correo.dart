/// HU-40 · Verificar mi correo: cómo sabe la app que se abrió desde el
/// enlace de confirmación que llega al registrarse.
///
/// El enlace de Supabase vuelve a la app con `?verificado=1` (y el código
/// que Supabase cambia por una sesión al arrancar). Si el enlace ya se usó o
/// venció, Supabase agrega `error_code` a la dirección.
abstract final class VerificacionCorreo {
  static const parametro = 'verificado';

  /// Si la app se abrió desde el enlace de confirmación del correo.
  static bool vieneDelEnlace(Uri direccion) =>
      direccion.queryParameters[parametro] == '1';

  /// Qué pasó con el enlace con el que se abrió la app.
  static EstadoEnlaceCorreo estado(Uri direccion) {
    if (!vieneDelEnlace(direccion)) return EstadoEnlaceCorreo.ninguno;
    final codigo = _codigoDeError(direccion);
    if (codigo == null) return EstadoEnlaceCorreo.verificado; // c1
    // c3 · Supabase no distingue "ya usado" de "vencido": los dos llegan
    // como otp_expired.
    if (codigo == 'otp_expired') return EstadoEnlaceCorreo.yaUsado;
    return EstadoEnlaceCorreo.error;
  }

  /// Dirección a la que vuelve el enlace del correo: la misma app, en la
  /// carpeta donde está publicada, con la marca. Ej.:
  /// http://localhost:54116/?verificado=1 o
  /// https://dcarvajal13.github.io/limpiaya/?verificado=1
  static String enlaceDeRegreso([Uri? base]) {
    final actual = base ?? Uri.base;
    return Uri(
      scheme: actual.scheme,
      host: actual.host,
      port: actual.hasPort ? actual.port : null,
      // GitHub Pages publica la app dentro de una carpeta (/limpiaya/):
      // se conserva esa ruta para no volver a la raíz del dominio.
      path: _carpetaDeLaApp(actual),
      queryParameters: {parametro: '1'},
    ).toString();
  }

  /// La ruta de la app sin la pantalla (que va después del #). Siempre
  /// termina en '/'.
  static String _carpetaDeLaApp(Uri direccion) {
    final ruta = direccion.path;
    if (ruta.isEmpty || ruta.endsWith('/')) return ruta.isEmpty ? '/' : ruta;
    final ultimo = ruta.substring(ruta.lastIndexOf('/') + 1);
    // ".../limpiaya/index.html" → ".../limpiaya/"; ".../limpiaya" → ".../limpiaya/"
    return ultimo.contains('.')
        ? ruta.substring(0, ruta.lastIndexOf('/') + 1)
        : '$ruta/';
  }

  /// El error puede venir en la consulta (?error_code=...) o, según el
  /// flujo, después del # (#error_code=...).
  static String? _codigoDeError(Uri direccion) {
    final enConsulta = direccion.queryParameters['error_code'];
    if (enConsulta != null) return enConsulta;
    final fragmento = direccion.fragment;
    if (!fragmento.contains('error_code=')) return null;
    final inicio = fragmento.indexOf('error_code=');
    try {
      return Uri.splitQueryString(fragmento.substring(inicio))['error_code'];
    } on FormatException {
      return null;
    }
  }
}

/// HU-40 · Resultado del enlace de confirmación con el que se abrió la app.
enum EstadoEnlaceCorreo {
  /// La app no se abrió desde ese enlace.
  ninguno,

  /// c1 · El correo quedó verificado.
  verificado,

  /// c3 · El enlace ya se había usado (o venció).
  yaUsado,

  /// Otro problema con el enlace.
  error,
}
