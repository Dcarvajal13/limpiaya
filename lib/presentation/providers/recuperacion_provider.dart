import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/recuperacion.dart';

/// HU-19 · true mientras la persona que llegó con el enlace de recuperación
/// no haya guardado su contraseña nueva. El router la manda a
/// "Nueva contraseña" mientras sea true.
final recuperandoContrasenaProvider =
    NotifierProvider<RecuperandoContrasena, bool>(RecuperandoContrasena.new);

class RecuperandoContrasena extends Notifier<bool> {
  @override
  bool build() => Recuperacion.vieneDelEnlace(Uri.base);

  /// Se llama al guardar la contraseña nueva.
  void terminar() => state = false;
}
