import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/postulante.dart';
import 'package:limpiaya/domain/services/servicio_service.dart';

Postulante _postulante(String id, EstadoPostulacion estado) => Postulante(
      postulacionId: id,
      trabajadoraId: 't-$id',
      nombre: 'Trabajadora $id',
      estado: estado,
      fecha: DateTime(2026, 11, 8),
    );

void main() {
  group('HU-15 · ¿se puede elegir?', () {
    final pendiente = _postulante('1', EstadoPostulacion.pendiente);
    final otra = _postulante('2', EstadoPostulacion.pendiente);

    test('c1: pendiente en una solicitud Publicada', () {
      expect(
        ServicioService.puedeElegir(
          postulante: pendiente,
          postulantes: [pendiente, otra],
          estadoSolicitud: EstadoSolicitud.publicada,
        ),
        isTrue,
      );
    });

    test('si el resumen no ha cargado, decide la lista', () {
      expect(
        ServicioService.puedeElegir(
          postulante: pendiente,
          postulantes: [pendiente, otra],
        ),
        isTrue,
      );
    });

    test('c4: no si la solicitud ya está Asignada', () {
      expect(
        ServicioService.puedeElegir(
          postulante: pendiente,
          postulantes: [pendiente],
          estadoSolicitud: EstadoSolicitud.asignada,
        ),
        isFalse,
      );
    });

    test('c4: no si ya hay una Aceptada en la lista', () {
      final aceptada = _postulante('3', EstadoPostulacion.aceptada);
      expect(
        ServicioService.puedeElegir(
          postulante: pendiente,
          postulantes: [aceptada, pendiente],
        ),
        isFalse,
      );
    });

    test('no si la solicitud está Cancelada', () {
      expect(
        ServicioService.puedeElegir(
          postulante: pendiente,
          postulantes: [pendiente],
          estadoSolicitud: EstadoSolicitud.cancelada,
        ),
        isFalse,
      );
    });
  });

  group('traducir errores de la base', () {
    test('un mensaje conocido se muestra tal cual', () {
      expect(
        ServicioService.traducir(
          'P0001: Esta trabajadora ya tiene un servicio en ese horario',
          ServicioService.mensajesElegir,
          ServicioService.mensajeErrorElegir,
        ),
        'Esta trabajadora ya tiene un servicio en ese horario',
      );
    });

    test('uno desconocido se cambia por el genérico', () {
      expect(
        ServicioService.traducir(
          'permission denied for function elegir_trabajadora',
          ServicioService.mensajesElegir,
          ServicioService.mensajeErrorElegir,
        ),
        ServicioService.mensajeErrorElegir,
      );
    });
  });
}
