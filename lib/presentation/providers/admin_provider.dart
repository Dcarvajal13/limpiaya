import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/cuenta_usuario.dart';
import '../../domain/entities/metricas_plataforma.dart';
import '../../domain/entities/resena_reportada.dart';

/// HU-34 · Cuentas de clientes y trabajadoras para administrar.
final cuentasAdminProvider = FutureProvider.autoDispose<List<CuentaUsuario>>(
  (ref) => ref.watch(adminRepositoryProvider).listarCuentas(),
  retry: (intentos, error) => null,
);

/// HU-35 · Cola de reseñas reportadas pendientes de moderación.
final resenasReportadasProvider =
    FutureProvider.autoDispose<List<ResenaReportada>>(
  (ref) => ref.watch(adminRepositoryProvider).listarResenasReportadas(),
  retry: (intentos, error) => null,
);

/// HU-36 · Métricas de la plataforma para el mes indicado (normalizado al día 1).
final metricasPlataformaProvider =
    FutureProvider.autoDispose.family<MetricasPlataforma, DateTime>(
  (ref, mes) => ref.watch(adminRepositoryProvider).metricas(mes),
  retry: (intentos, error) => null,
);
