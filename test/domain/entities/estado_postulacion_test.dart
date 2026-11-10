import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';

EstadoPostulacion _resolver(
  EstadoPostulacion guardado,
  EstadoSolicitud solicitud, {
  String? asignada,
}) =>
    EstadoPostulacion.resolver(
      guardado: guardado,
      estadoSolicitud: solicitud,
      trabajadoraAsignadaId: asignada,
      miId: 'yo',
    );

void main() {
  group('EstadoPostulacion.resolver (HU-13)', () {
    test('c1: pendiente mientras la solicitud sigue publicada', () {
      expect(
        _resolver(EstadoPostulacion.pendiente, EstadoSolicitud.publicada),
        EstadoPostulacion.pendiente,
      );
    });

    test('c1: aceptada si la solicitud quedó asignada a mí', () {
      expect(
        _resolver(
          EstadoPostulacion.aceptada,
          EstadoSolicitud.asignada,
          asignada: 'yo',
        ),
        EstadoPostulacion.aceptada,
      );
    });

    test('c1: solicitud cancelada gana sobre pendiente y aceptada', () {
      for (final guardado in [
        EstadoPostulacion.pendiente,
        EstadoPostulacion.aceptada,
      ]) {
        expect(
          _resolver(guardado, EstadoSolicitud.cancelada),
          EstadoPostulacion.solicitudCancelada,
        );
      }
    });

    test('c2: el cliente eligió a otra → No seleccionada aunque siga pendiente',
        () {
      expect(
        _resolver(
          EstadoPostulacion.pendiente,
          EstadoSolicitud.asignada,
          asignada: 'otra',
        ),
        EstadoPostulacion.noSeleccionada,
      );
      expect(
        _resolver(
          EstadoPostulacion.pendiente,
          EstadoSolicitud.completada,
          asignada: 'otra',
        ),
        EstadoPostulacion.noSeleccionada,
      );
    });

    test('la retirada no cambia, aunque se cancele o se asigne a otra', () {
      expect(
        _resolver(EstadoPostulacion.retirada, EstadoSolicitud.cancelada),
        EstadoPostulacion.retirada,
      );
    });

    test('desdeDb conoce los 5 valores del enum de Postgres', () {
      for (final e in EstadoPostulacion.values) {
        expect(EstadoPostulacion.desdeDb(e.valorDb), e);
      }
    });
  });
}
