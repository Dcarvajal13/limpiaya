import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/core/errors/app_exception.dart';
import 'package:limpiaya/domain/entities/archivo_foto.dart';
import 'package:limpiaya/domain/entities/mi_verificacion.dart';
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

  int enviadas = 0;

  @override
  Future<MiVerificacion?> miUltima() async => null;

  @override
  Future<void> enviar({
    required ArchivoFoto cedula,
    required ArchivoFoto selfie,
  }) async =>
      enviadas++;
}

ArchivoFoto _foto(String nombre, {int bytes = 1000}) =>
    ArchivoFoto(bytes: List.filled(bytes, 1), nombre: nombre);

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

  group('HU-21 · enviar la verificación', () {
    test('c1: con cédula y selfie válidas se envía', () async {
      await servicio.enviar(
        cedula: _foto('cedula.jpg'),
        selfie: _foto('selfie.PNG'),
      );
      expect(repo.enviadas, 1);
    });

    test('sin cédula pide subirla', () async {
      await expectLater(
        servicio.enviar(selfie: _foto('selfie.jpg')),
        throwsA(isA<AppException>().having(
            (e) => e.mensaje, 'mensaje', 'Sube la foto de tu cédula')),
      );
      expect(repo.enviadas, 0);
    });

    test('sin selfie pide subirla', () async {
      await expectLater(
        servicio.enviar(cedula: _foto('cedula.jpg')),
        throwsA(isA<AppException>().having((e) => e.mensaje, 'mensaje',
            'Sube la selfie sosteniendo tu cédula')),
      );
    });

    test('solo acepta JPG o PNG de hasta 5 MB', () {
      expect(VerificacionService.validarFoto(_foto('a.jpeg')), isNull);
      expect(VerificacionService.validarFoto(_foto('a.pdf')),
          'La foto debe ser JPG o PNG');
      expect(
        VerificacionService.validarFoto(
            _foto('a.jpg', bytes: 5 * 1024 * 1024 + 1)),
        'La foto no puede pasar de 5 MB',
      );
    });
  });
}
