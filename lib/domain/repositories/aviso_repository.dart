import '../entities/aviso.dart';
import '../entities/correo_aviso.dart';

/// HU-50 y HU-49 · Contrato para avisos en la app y avisos por correo.
abstract interface class AvisoRepository {
  /// Avisos del usuario con sesión, ordenados del más reciente al más antiguo.
  Future<List<Aviso>> misAvisos();

  /// Flujo en vivo de los avisos del usuario (Supabase Realtime).
  Stream<List<Aviso>> streamAvisos();

  /// Marca un aviso como leído (HU-50).
  Future<void> marcarLeido(String avisoId);

  /// Marca todos los avisos sin leer como leídos (HU-50).
  Future<void> marcarTodosLeidos();

  /// HU-49 · Correos de aviso generados o programados para el usuario.
  Future<List<CorreoAviso>> misCorreos();

  /// HU-49 · Activa o desactiva la recepción de avisos por correo.
  Future<void> actualizarAvisosCorreo(bool activo);
}
