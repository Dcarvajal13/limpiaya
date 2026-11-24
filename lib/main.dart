import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

/// Punto de entrada de LimpiaYa.
///
/// Para correr la app:
///   flutter run -d chrome --dart-define-from-file=env.json
/// (o F5 en VS Code, que ya usa esa configuración).
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Accesibilidad web: Flutter dibuja la app en un <canvas> y, para ahorrar
  // trabajo, no arma el árbol semántico hasta que alguien pulsa un botón
  // oculto ("Enable accessibility"). Sin ese árbol, NVDA y Lighthouse solo
  // ven una página vacía. Con ensureSemantics() el árbol (roles, nombres,
  // estados ARIA) está siempre en el DOM.
  if (kIsWeb) binding.ensureSemantics();

  Env.validar();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  // ProviderScope es lo que hace funcionar a Riverpod en toda la app.
  runApp(const ProviderScope(child: LimpiaYaApp()));
}
