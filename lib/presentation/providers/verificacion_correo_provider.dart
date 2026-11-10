import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/verificacion_correo.dart';

/// HU-40 · Qué pasó con el enlace de confirmación con el que se abrió la
/// app. Mientras no sea `ninguno`, el router muestra la pantalla
/// "Correo verificado".
final enlaceCorreoProvider =
    NotifierProvider<EnlaceCorreo, EstadoEnlaceCorreo>(EnlaceCorreo.new);

class EnlaceCorreo extends Notifier<EstadoEnlaceCorreo> {
  @override
  EstadoEnlaceCorreo build() => VerificacionCorreo.estado(Uri.base);

  /// Se llama al seguir desde la pantalla "Correo verificado".
  void terminar() => state = EstadoEnlaceCorreo.ninguno;
}
