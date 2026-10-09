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
  WidgetsFlutterBinding.ensureInitialized();

  Env.validar();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );

  // ProviderScope es lo que hace funcionar a Riverpod en toda la app.
  runApp(const ProviderScope(child: LimpiaYaApp()));
}
