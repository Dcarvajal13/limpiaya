import 'package:limpiaya/domain/entities/direccion_guardada.dart';
import 'package:limpiaya/domain/repositories/direcciones_repository.dart';

/// Direcciones guardadas en memoria, para las pruebas.
class DireccionesFalsas implements DireccionesRepository {
  DireccionesFalsas([List<DireccionGuardada> iniciales = const []])
      : direcciones = [...iniciales];

  final List<DireccionGuardada> direcciones;

  @override
  Future<List<DireccionGuardada>> misDirecciones() async => [...direcciones];

  @override
  Future<void> guardar({
    String? id,
    required String nombre,
    required int zonaId,
    required String direccion,
    String? puntoReferencia,
  }) async {
    final nueva = DireccionGuardada(
      id: id ?? 'd${direcciones.length + 1}',
      nombre: nombre.trim(),
      zonaId: zonaId,
      direccion: direccion.trim(),
      puntoReferencia: puntoReferencia,
    );
    direcciones
      ..removeWhere((d) => d.id == nueva.id)
      ..add(nueva);
  }

  @override
  Future<void> eliminar(String id) async =>
      direcciones.removeWhere((d) => d.id == id);
}
