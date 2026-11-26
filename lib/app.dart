import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget raíz: conecta el tema y las rutas.
class LimpiaYaApp extends ConsumerWidget {
  const LimpiaYaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LimpiaYa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      // Accesibilidad (WCAG 3.1.1 y 3.1.2): sin esto los textos que pone
      // Flutter (selector de fecha, "Back", "Dismiss", "Close"...) salen en
      // inglés y el lector de pantalla los lee con la voz equivocada.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
