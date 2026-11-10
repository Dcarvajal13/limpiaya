import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_postulacion.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/postulante.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/services/servicio_service.dart';

Postulante _postulante(String id, EstadoPostulacion estado) => Postulante(
      postulacionId: id,
      trabajadoraId: 't-$id',
      nombre: 'Trabajadora $id',
      estado: estado,
      fecha: DateTime(2026, 11, 8),
    );

Solicitud _solicitud(EstadoSolicitud estado, DateTime inicio) => Solicitud(
      id: 's1',
      clienteId: 'c1',
      trabajadoraId: 't1',
      estado: estado,
      tipo: TipoLimpieza.general,
      zonaId: 1,
      zona: 'Petare',
      inicio: inicio,
      horasEstimadas: 4,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 1,
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

  group('HU-17 · ¿se puede marcar como completado?', () {
    final ahora = DateTime(2026, 11, 14, 12);

    test('c1: Asignado y ya empezó', () {
      expect(
        ServicioService.puedeCompletar(
          _solicitud(EstadoSolicitud.asignada, DateTime(2026, 11, 14, 9)),
          ahora,
        ),
        isTrue,
      );
    });

    test('c1: justo a la hora de inicio también', () {
      expect(
        ServicioService.puedeCompletar(
          _solicitud(EstadoSolicitud.asignada, ahora),
          ahora,
        ),
        isTrue,
      );
    });

    test('c2: no si todavía no ha empezado', () {
      expect(
        ServicioService.puedeCompletar(
          _solicitud(EstadoSolicitud.asignada, DateTime(2026, 11, 15, 9)),
          ahora,
        ),
        isFalse,
      );
    });

    test('no si está Publicada, Completada o Cancelada', () {
      for (final estado in [
        EstadoSolicitud.publicada,
        EstadoSolicitud.completada,
        EstadoSolicitud.cancelada,
      ]) {
        expect(
          ServicioService.puedeCompletar(
            _solicitud(estado, DateTime(2026, 11, 14, 9)),
            ahora,
          ),
          isFalse,
          reason: estado.etiqueta,
        );
      }
    });
  });

  group('HU-28 · cancelar un servicio asignado', () {
    test('c1: solo se cancela un servicio Asignado', () {
      expect(ServicioService.puedeCancelar(EstadoSolicitud.asignada), isTrue);
    });

    test('c3: uno Completado ya no; tampoco Publicada ni Cancelada', () {
      for (final estado in [
        EstadoSolicitud.completada,
        EstadoSolicitud.publicada,
        EstadoSolicitud.cancelada,
      ]) {
        expect(
          ServicioService.puedeCancelar(estado),
          isFalse,
          reason: estado.etiqueta,
        );
      }
    });

    test('cancelación tardía: menos de 24 horas antes', () {
      final ahora = DateTime(2026, 11, 10, 9);
      expect(
        ServicioService.esCancelacionTardia(DateTime(2026, 11, 11, 8), ahora),
        isTrue,
      );
      expect(
        ServicioService.esCancelacionTardia(DateTime(2026, 11, 11, 10), ahora),
        isFalse,
      );
    });

    test('c2: "Elige un motivo" de la base se muestra tal cual', () {
      expect(
        ServicioService.traducir(
          'Elige un motivo',
          ServicioService.mensajesCancelar,
          ServicioService.mensajeErrorCancelar,
        ),
        ServicioService.mensajeEligeMotivo,
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
