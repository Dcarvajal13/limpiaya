import 'package:flutter/widgets.dart';

/// Reglas de movimiento de LimpiaYa.
///
/// - Lo que entra o responde a un toque usa [salida]: arranca rápido y
///   frena suave, así se siente inmediato.
/// - Lo que se desplaza dentro de la pantalla usa [desplazamiento].
/// - Las animaciones de la interfaz duran menos de 300 ms. Solo los
///   ciclos de la landing (reseñas, demo) son más largos.
/// - Si el sistema pide reducir el movimiento, no hay ciclos ni
///   desplazamientos: se muestra el estado final.
abstract final class Movimiento {
  /// Arranca rápido y frena suave (entradas, respuestas a un toque).
  static const salida = Cubic(0.23, 1, 0.32, 1);

  /// Acelera y frena (cosas que se mueven de un lugar a otro).
  static const desplazamiento = Cubic(0.77, 0, 0.175, 1);

  static const rapido = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const entrada = Duration(milliseconds: 420);

  /// Ciclos que se repiten solos (reseñas que rotan, demo de la tarjeta,
  /// pasos que avanzan). Las pruebas lo ponen en false: un ciclo infinito
  /// no deja terminar `pumpAndSettle`.
  static bool ciclos = true;

  /// Si se pueden mostrar animaciones (respeta "reducir movimiento").
  static bool animar(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);

  /// Si los ciclos pueden correr en esta pantalla.
  static bool ciclosActivos(BuildContext context) =>
      ciclos && animar(context);
}
