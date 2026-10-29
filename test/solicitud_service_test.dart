import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/domain/entities/direccion_cliente.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/nueva_solicitud.dart';
import 'package:limpiaya/domain/entities/quien_pone_productos.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/entities/zona.dart';
import 'package:limpiaya/domain/repositories/solicitud_repository.dart';
import 'package:limpiaya/domain/services/solicitud_service.dart';

/// Repositorio falso: no habla con Supabase, solo cuenta las publicaciones.
class _RepositorioFalso implements SolicitudRepository {
  @override
  Future<void> cancelar(String id, {String? motivo}) async {}

  int publicadas = 0;

  @override
  Future<String> publicar(NuevaSolicitud solicitud) async {
    publicadas++;
    return 'id-de-prueba';
  }

  @override
  Future<DireccionCliente?> miDireccion() async => null;

  @override
  Future<List<Zona>> misZonas() async => const [];

  @override
  Future<List<SolicitudDisponible>> disponibles() async => const [];

  @override
  Future<List<Solicitud>> misSolicitudes() async => const [];

  @override
  Future<SolicitudDisponible?> solicitudDisponible(String id) async => null;
}

void main() {
  final ahora = DateTime(2026, 10, 20, 10);
  late _RepositorioFalso repo;
  late SolicitudService servicio;

  setUp(() {
    repo = _RepositorioFalso();
    servicio = SolicitudService(repo, ahora: () => ahora);
  });

  NuevaSolicitud solicitud({
    DateTime? inicio,
    double pago = 30,
    double horas = 4,
    QuienPoneProductos? productos = QuienPoneProductos.cliente,
  }) {
    return NuevaSolicitud(
      tipo: TipoLimpieza.general,
      zonaId: 1,
      direccion: '4ta avenida, edificio Ávila',
      inicio: inicio ?? DateTime(2026, 10, 24, 9),
      horasEstimadas: horas,
      pagoOfrecido: pago,
      metodoPago: MetodoPago.pagoMovil,
      habitaciones: 3,
      banos: 2,
      tieneMascotas: false,
      productosPor: productos,
    );
  }

  test('HU-07 c1: con datos válidos publica la solicitud', () async {
    await servicio.publicar(solicitud());
    expect(repo.publicadas, 1);
  });

  test('HU-07 c2: rechaza una fecha que ya pasó', () {
    expect(
      servicio.publicar(solicitud(inicio: DateTime(2026, 10, 19, 9))),
      throwsA(isA<AppException>()),
    );
  });

  test('HU-07 c3: rechaza un pago vacío o de 0', () {
    expect(servicio.publicar(solicitud(pago: 0)), throwsA(isA<AppException>()));
  });

  test('HU-43 c2: exige indicar quién pone los productos', () {
    expect(
      servicio.publicar(solicitud(productos: null)),
      throwsA(isA<AppException>()),
    );
  });

  test('rechaza horas fuera del rango de 2 a 10', () {
    expect(servicio.publicar(solicitud(horas: 1)), throwsA(isA<AppException>()));
    expect(servicio.publicar(solicitud(horas: 11)), throwsA(isA<AppException>()));
  });

  test('HU-52: la tarifa es el 10 % y el total la suma', () {
    expect(SolicitudService.tarifa(30), 3);
    expect(SolicitudService.total(30), 33);
  });

  group('HU-10 · cancelar', () {
    Solicitud conEstado(EstadoSolicitud estado) => Solicitud(
          id: 's1',
          clienteId: 'c1',
          estado: estado,
          tipo: TipoLimpieza.general,
          zonaId: 1,
          zona: 'Chacao',
          inicio: DateTime(2026, 10, 24, 9),
          horasEstimadas: 4,
          pagoOfrecido: 30,
          metodoPago: MetodoPago.pagoMovil,
          numPostulantes: 0,
        );

    test('solo se puede cancelar una solicitud Publicada', () {
      expect(SolicitudService.sePuedeCancelar(
          conEstado(EstadoSolicitud.publicada)), isTrue);
      for (final estado in [
        EstadoSolicitud.asignada,
        EstadoSolicitud.completada,
        EstadoSolicitud.cancelada,
      ]) {
        expect(SolicitudService.sePuedeCancelar(conEstado(estado)), isFalse);
      }
    });

    test('cancelar una asignada da error', () {
      expect(
        () => servicio.cancelar(conEstado(EstadoSolicitud.asignada)),
        throwsA(isA<AppException>()),
      );
    });
  });
}
