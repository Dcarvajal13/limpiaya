import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/entities/sesion.dart';
import 'package:limpiaya/presentation/providers/sesion_provider.dart';

/// Sesión de un cliente, para las pruebas. Por defecto con la identidad
/// aprobada (puede publicar).
class SesionClienteFalsa extends SesionNotifier {
  SesionClienteFalsa([this.verificacion = 'aprobada']);

  final String? verificacion;

  @override
  Future<Sesion?> build() async => Sesion(
        id: 'c1',
        rol: RolUsuario.cliente,
        nombre: 'María Alejandra',
        perfilCompleto: true,
        verificacion: verificacion,
      );
}
