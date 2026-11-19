import '../entities/direccion_guardada.dart';

/// Reglas de las direcciones guardadas del cliente.
///
/// Vive en el dominio y no conoce Supabase ni Flutter. Las mismas reglas
/// están en la base (migración direcciones_guardadas).
abstract final class DireccionesService {
  static const maximo = 10;
  static const largoNombre = 40;

  static const errorCargar = 'No pudimos cargar tus direcciones.';
  static const errorGuardar =
      'No pudimos guardar la dirección. Intenta de nuevo.';
  static const errorEliminar =
      'No pudimos eliminar la dirección. Intenta de nuevo.';
  static const nombreRepetido = 'Ya tienes una dirección con ese nombre';
  static const limite = 'Puedes guardar hasta 10 direcciones';

  /// Nombres que se sugieren al guardar una dirección nueva.
  static const sugerencias = ['Casa', 'Trabajo', 'Casa de mis padres'];

  /// Valida el nombre ("Casa"). [otras] son las que ya tiene el cliente;
  /// [id] es la que se está editando (puede conservar su propio nombre).
  static String? validarNombre(
    String? nombre,
    List<DireccionGuardada> otras, {
    String? id,
  }) {
    final limpio = (nombre ?? '').trim();
    if (limpio.isEmpty) return 'Ponle un nombre, por ejemplo "Casa"';
    if (limpio.length > largoNombre) return 'Máximo $largoNombre caracteres';
    final repetido = otras.any(
      (d) => d.id != id && _clave(d.nombre) == _clave(limpio),
    );
    return repetido ? nombreRepetido : null;
  }

  /// Si puede guardar una más.
  static bool puedeAgregar(List<DireccionGuardada> direcciones) =>
      direcciones.length < maximo;

  /// La dirección guardada que coincide con lo escrito en el formulario, o
  /// null si es una dirección nueva.
  static DireccionGuardada? coincidencia(
    List<DireccionGuardada> direcciones, {
    required int? zonaId,
    required String direccion,
  }) {
    if (zonaId == null) return null;
    final escrita = _clave(direccion);
    for (final d in direcciones) {
      if (d.zonaId == zonaId && _clave(d.direccion) == escrita) return d;
    }
    return null;
  }

  /// Un nombre libre para sugerir ("Casa", luego "Trabajo"…, luego
  /// "Dirección 4").
  static String nombreSugerido(List<DireccionGuardada> direcciones) {
    final usados = {for (final d in direcciones) _clave(d.nombre)};
    for (final s in sugerencias) {
      if (!usados.contains(_clave(s))) return s;
    }
    var n = direcciones.length + 1;
    while (usados.contains(_clave('Dirección $n'))) {
      n++;
    }
    return 'Dirección $n';
  }

  /// Mensaje de la base → mensaje para el cliente.
  static String traducir(String mensaje) {
    if (mensaje.contains('direcciones_cliente_nombre_idx') ||
        mensaje.contains('duplicate key')) {
      return nombreRepetido;
    }
    if (mensaje.contains(limite)) return limite;
    return errorGuardar;
  }

  static String _clave(String texto) =>
      texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
