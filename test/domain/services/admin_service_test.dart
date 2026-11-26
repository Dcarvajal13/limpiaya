import 'package:flutter_test/flutter_test.dart';
import 'package:limpiaya/domain/entities/cuenta_usuario.dart';
import 'package:limpiaya/domain/entities/metricas_plataforma.dart';
import 'package:limpiaya/domain/entities/rol_usuario.dart';
import 'package:limpiaya/domain/services/admin_service.dart';

void main() {
  group('HU-34 · suspensión de cuentas', () {
    test('exige motivo no vacío al suspender', () {
      expect(
        AdminService.validarMotivoSuspension(''),
        AdminService.errorMotivoSuspension,
      );
      expect(
        AdminService.validarMotivoSuspension('   '),
        AdminService.errorMotivoSuspension,
      );
      expect(
        AdminService.validarMotivoSuspension('Incumplimiento reiterado'),
        isNull,
      );
    });

    test('filtra por búsqueda y solo suspendidas', () {
      final cuentas = [
        CuentaUsuario(
          id: '1',
          nombre: 'María Rodríguez',
          rol: RolUsuario.cliente,
          activo: true,
          suspendido: false,
          serviciosActivos: 1,
          creadoEn: DateTime(2026, 11, 1),
        ),
        CuentaUsuario(
          id: '2',
          nombre: 'Carmen López',
          rol: RolUsuario.trabajadora,
          activo: true,
          suspendido: true,
          motivoSuspension: 'Cancelaciones reiteradas',
          serviciosActivos: 0,
          creadoEn: DateTime(2026, 11, 2),
        ),
      ];

      expect(
        AdminService.filtrarCuentas(cuentas, soloSuspendidas: true).length,
        1,
      );
      expect(
        AdminService.filtrarCuentas(cuentas, busqueda: 'maría').single.id,
        '1',
      );
    });
  });

  group('HU-35 · moderación de reseñas', () {
    test('exige motivo al reportar una reseña', () {
      expect(
        AdminService.validarMotivoReporte(''),
        AdminService.errorMotivoReporte,
      );
      expect(AdminService.validarMotivoReporte('Lenguaje ofensivo'), isNull);
    });
  });

  group('HU-36 · métricas de la plataforma', () {
    test('calcula porcentajes seguros sin dividir por cero', () {
      expect(AdminService.porcentaje(0, 0), 0);
      expect(AdminService.porcentaje(3, 4), 75.0);
    });

    test('resume correctamente la hipótesis del MVP', () {
      final vacias = MetricasPlataforma(
        mes: DateTime(2026, 11, 1),
        totalSolicitudes: 0,
        solicitudesConPostulacion: 0,
        pctConPostulacion: 0,
        solicitudesAsignadas: 0,
        solicitudesCompletadas: 0,
        solicitudesCanceladas: 0,
        pctCompletado: 0,
        clientesNuevos: 0,
        trabajadorasNuevas: 0,
        trabajadorasVerificadas: 0,
        volumenUsd: 0,
      );
      expect(
        AdminService.resumenHipotesis(vacias),
        contains('Aún no hay solicitudes'),
      );

      final saludable = MetricasPlataforma(
        mes: DateTime(2026, 11, 1),
        totalSolicitudes: 20,
        solicitudesConPostulacion: 16,
        pctConPostulacion: 80,
        solicitudesAsignadas: 3,
        solicitudesCompletadas: 12,
        solicitudesCanceladas: 2,
        pctCompletado: 60,
        clientesNuevos: 5,
        trabajadorasNuevas: 4,
        trabajadorasVerificadas: 10,
        volumenUsd: 420,
      );
      expect(
        AdminService.resumenHipotesis(saludable),
        contains('Tracción saludable'),
      );
    });
  });
}
