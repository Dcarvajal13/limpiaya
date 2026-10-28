import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/domain/entities/verificacion_pendiente.dart';
import 'package:limpiaya/domain/repositories/verificacion_repository.dart';
import 'package:limpiaya/domain/services/verificacion_service.dart';

/// Repositorio falso: no habla con Supabase, solo anota lo que se pidió.
class _RepositorioFalso implements VerificacionRepository {
  final aprobadas = <String>[];
  final rechazadas = <String, String>{};

  @override
  Future<List<VerificacionPendiente>> pendientes() async => const [];

  @override
  Future<void> aprobar(String id) async => aprobadas.add(id);

  @override
  Future<void> rechazar(String id, String motivo) async =>
      rechazadas[id] = motivo;
}

void main() {
  late _RepositorioFalso repo;
  late VerificacionService servicio;

  setUp(() {
    repo = _RepositorioFalso();
    servicio = VerificacionService(repo);
  });

  test('HU-33 c2: aprobar llama al repositorio con la verificación', () async {
    await servicio.aprobar('v1');
    expect(repo.aprobadas, ['v1']);
  });

  test('HU-33 c3: rechazar sin motivo muestra "Indica el motivo"', () async {
    await expectLater(
      servicio.rechazar('v1', ''),
      throwsA(isA<AppException>()
          .having((e) => e.mensaje, 'mensaje', 'Indica el motivo')),
    );
    expect(repo.rechazadas, isEmpty);
  });

  test('HU-33 c3: un motivo con solo espacios cuenta como vacío', () async {
    await expectLater(
      servicio.rechazar('v1', '   '),
      throwsA(isA<AppException>()
          .having((e) => e.mensaje, 'mensaje', 'Indica el motivo')),
    );
    expect(repo.rechazadas, isEmpty);
  });

  test('rechazar guarda el motivo sin espacios sobrantes', () async {
    await servicio.rechazar('v1', '  La cédula no se lee  ');
    expect(repo.rechazadas, {'v1': 'La cédula no se lee'});
  });

  test('el motivo no puede pasar de 300 caracteres', () async {
    expect(VerificacionService.validarMotivo('a' * 300), isNull);
    expect(VerificacionService.validarMotivo('a' * 301), isNotNull);
    await expectLater(
      servicio.rechazar('v1', 'a' * 301),
      throwsA(isA<AppException>()),
    );
    expect(repo.rechazadas, isEmpty);
  });
}
