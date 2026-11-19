import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/estado_solicitud.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/orden_trabajadoras.dart';
import 'package:limpiaya/domain/entities/perfil_publico.dart';
import 'package:limpiaya/domain/entities/solicitud.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/services/busqueda_service.dart';

PerfilPublico _t(
  String nombre, {
  double? promedio,
  int servicios = 0,
  bool destacada = false,
  List<int> zonas = const [1],
}) =>
    PerfilPublico(
      id: nombre,
      nombre: nombre,
      promedio: promedio,
      totalResenas: promedio == null ? 0 : 3,
      serviciosCompletados: servicios,
      destacada: destacada,
      zonaIds: zonas,
    );

Solicitud _s(
  String id, {
  EstadoSolicitud estado = EstadoSolicitud.publicada,
  int zona = 1,
  int dias = 2,
}) =>
    Solicitud(
      id: id,
      clienteId: 'c1',
      estado: estado,
      tipo: TipoLimpieza.general,
      zonaId: zona,
      zona: 'Zona $zona',
      inicio: DateTime(2026, 11, 10).add(Duration(days: dias)),
      horasEstimadas: 3,
      pagoOfrecido: 30,
      metodoPago: MetodoPago.pagoMovil,
      numPostulantes: 0,
    );

List<String> _nombres(List<PerfilPublico> lista) =>
    [for (final t in lista) t.nombre];

void main() {
  final ahora = DateTime(2026, 11, 10);

  group('HU-25 c2 · ordenar', () {
    final lista = [
      _t('Nueva'),
      _t('Buena', promedio: 4.2, servicios: 20),
      _t('Mejor', promedio: 4.9, servicios: 3),
      _t('Empate', promedio: 4.9, servicios: 12, destacada: true),
    ];

    test('por calificación: de mayor a menor promedio, sin reseñas al final',
        () {
      expect(
        _nombres(BusquedaService.ordenar(lista, OrdenTrabajadoras.calificacion)),
        ['Empate', 'Mejor', 'Buena', 'Nueva'],
      );
    });

    test('por servicios completados: de más a menos', () {
      expect(
        _nombres(BusquedaService.ordenar(lista, OrdenTrabajadoras.servicios)),
        ['Buena', 'Empate', 'Mejor', 'Nueva'],
      );
    });

    test('no cambia la lista original', () {
      BusquedaService.ordenar(lista, OrdenTrabajadoras.calificacion);
      expect(_nombres(lista).first, 'Nueva');
    });
  });

  group('HU-25 c3 · a qué solicitudes se puede invitar', () {
    final mias = [
      _s('ok'),
      _s('otra-zona', zona: 2),
      _s('cancelada', estado: EstadoSolicitud.cancelada),
      _s('asignada', estado: EstadoSolicitud.asignada),
      _s('pasada', dias: -1),
    ];

    test('solo Publicadas, futuras y en una zona de ella', () {
      final disponibles = BusquedaService.solicitudesParaInvitar(
        mias,
        _t('Carmen', zonas: [1]),
        ahora: ahora,
      );
      expect([for (final s in disponibles) s.id], ['ok']);
    });

    test('publicadas() ignora la zona', () {
      final publicadas = BusquedaService.publicadas(mias, ahora: ahora);
      expect([for (final s in publicadas) s.id], ['ok', 'otra-zona']);
    });
  });

  test('traduce los mensajes de la base', () {
    expect(
      BusquedaService.traducir('ERROR: Ya la invitaste a esta solicitud'),
      'Ya la invitaste a esta solicitud',
    );
    expect(BusquedaService.traducir('algo raro'), BusquedaService.errorInvitar);
  });

  group('Invitada', () {
    final invitaciones = [
      (solicitudId: 'vigente', trabajadoraId: 't1'),
      (solicitudId: 'vieja', trabajadoraId: 't2'),
    ];

    test('solo cuentan las invitaciones a solicitudes publicadas', () {
      final publicadas = [_s('vigente'), _s('otra')];
      expect(BusquedaService.invitadas(invitaciones, publicadas), {'t1'});
    });

    test('el diálogo solo ofrece las solicitudes a las que no la invité', () {
      final disponibles = [_s('vigente'), _s('otra')];
      final pendientes =
          BusquedaService.sinInvitar(disponibles, invitaciones, 't1');
      expect([for (final s in pendientes) s.id], ['otra']);
      expect(
        BusquedaService.sinInvitar(disponibles, invitaciones, 't3').length,
        2,
      );
    });
  });

  test('confirmación con el primer nombre', () {
    expect(
      BusquedaService.invitada('Carmen Pérez'),
      'Invitaste a Carmen. Verá tu solicitud marcada como «Te invitaron».',
    );
  });
}
