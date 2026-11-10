import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/metodo_pago.dart';
import 'package:limpiaya/domain/entities/solicitud_disponible.dart';
import 'package:limpiaya/domain/entities/tipo_limpieza.dart';
import 'package:limpiaya/domain/services/filtro_solicitudes.dart';

SolicitudDisponible _solicitud(
  String id, {
  TipoLimpieza tipo = TipoLimpieza.general,
  int zonaId = 1,
  DateTime? inicio,
  bool tieneMascotas = false,
}) {
  return SolicitudDisponible(
    id: id,
    tipo: tipo,
    zonaId: zonaId,
    zona: 'Zona $zonaId',
    inicio: inicio ?? DateTime(2026, 10, 17, 8),
    horasEstimadas: 5,
    pagoOfrecido: 30,
    metodoPago: MetodoPago.pagoMovil,
    numPostulantes: 0,
    tieneMascotas: tieneMascotas,
  );
}

void main() {
  final lista = [
    _solicitud('a'),
    _solicitud(
      'b',
      tipo: TipoLimpieza.profunda,
      zonaId: 2,
      inicio: DateTime(2026, 10, 19, 7),
      tieneMascotas: true,
    ),
    _solicitud(
      'c',
      tipo: TipoLimpieza.planchado,
      zonaId: 3,
      inicio: DateTime(2026, 10, 17, 14),
    ),
  ];

  List<String> ids(FiltroSolicitudes filtro) =>
      filtrarSolicitudes(lista, filtro).map((s) => s.id).toList();

  test('HU-11 c2: sin filtros se ven todas', () {
    expect(ids(const FiltroSolicitudes()), ['a', 'b', 'c']);
    expect(const FiltroSolicitudes().hayFiltros, isFalse);
  });

  test('HU-11 c2: filtra por tipo de limpieza', () {
    expect(ids(const FiltroSolicitudes(tipo: TipoLimpieza.profunda)), ['b']);
  });

  test('HU-11 c2: "Desde la fecha" deja ese día y los siguientes', () {
    // El 17 a las 14:00 también cuenta aunque la fecha elegida sea a las 0:00.
    expect(ids(FiltroSolicitudes(fecha: DateTime(2026, 10, 17, 23))), ['a', 'b', 'c']);
    expect(ids(FiltroSolicitudes(fecha: DateTime(2026, 10, 18))), ['b']);
    expect(ids(FiltroSolicitudes(fecha: DateTime(2026, 10, 20))), isEmpty);
  });

  test('"Sin mascotas" oculta las casas con mascotas', () {
    const filtro = FiltroSolicitudes(sinMascotas: true);
    expect(ids(filtro), ['a', 'c']);
    expect(filtro.hayFiltros, isTrue);
  });

  test('desmarcar una zona oculta sus solicitudes', () {
    expect(ids(const FiltroSolicitudes(zonasOcultas: {2})), ['a', 'c']);
  });

  test('los filtros se combinan', () {
    final filtro = FiltroSolicitudes(
      tipo: TipoLimpieza.planchado,
      fecha: DateTime(2026, 10, 17),
      sinMascotas: true,
    );
    expect(ids(filtro), ['c']);
  });

  test('si nada coincide, la lista queda vacía', () {
    expect(
      ids(const FiltroSolicitudes(tipo: TipoLimpieza.postMudanza)),
      isEmpty,
    );
  });
}
