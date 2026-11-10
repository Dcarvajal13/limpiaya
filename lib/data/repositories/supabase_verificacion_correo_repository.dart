import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/router/verificacion_correo.dart';
import '../../domain/repositories/verificacion_correo_repository.dart';

/// Implementación de VerificacionCorreoRepository usando Supabase Auth
/// (HU-40).
///
/// Requiere en Supabase → Authentication → Sign In / Providers → Email la
/// opción "Confirm email" activa.
class SupabaseVerificacionCorreoRepository
    implements VerificacionCorreoRepository {
  SupabaseVerificacionCorreoRepository(this._client);

  final SupabaseClient _client;

  static const errorReenviar =
      'No pudimos reenviar el correo. Intenta de nuevo en un momento.';

  @override
  Future<void> reenviar(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: VerificacionCorreo.enlaceDeRegreso(),
      );
    } on AuthException catch (e) {
      if (e.code == 'over_email_send_rate_limit' || e.statusCode == '429') {
        throw const AppException(
          'Ya te enviamos un correo hace poco. Espera un minuto e intenta '
          'de nuevo.',
        );
      }
      throw const AppException(errorReenviar);
    } on Exception {
      throw const AppException(
        'No pudimos reenviar el correo. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }
}
