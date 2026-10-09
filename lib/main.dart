import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Las claves se leen de env.json al correr:
// flutter run -d chrome --dart-define-from-file=env.json
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    throw Exception(
      'Faltan las claves de Supabase. '
      'Corre: flutter run -d chrome --dart-define-from-file=env.json',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
  runApp(const LimpiaYaApp());
}

class LimpiaYaApp extends StatelessWidget {
  const LimpiaYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LimpiaYa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const PruebaConexionScreen(),
    );
  }
}

/// Pantalla temporal para comprobar HD-02.
/// Se reemplaza cuando armemos la estructura por capas.
class PruebaConexionScreen extends StatefulWidget {
  const PruebaConexionScreen({super.key});

  @override
  State<PruebaConexionScreen> createState() => _PruebaConexionScreenState();
}

class _PruebaConexionScreenState extends State<PruebaConexionScreen> {
  String _resultado = 'Probando conexión con Supabase...';

  @override
  void initState() {
    super.initState();
    _probarConexion();
  }

  Future<void> _probarConexion() async {
    try {
      // Intenta entrar con un usuario que no existe. Si Supabase responde
      // "credenciales inválidas", la URL y la clave funcionan.
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'prueba-conexion@limpiaya.test',
        password: 'no-existe-123',
      );
      _mostrar('✅ Conectado a Supabase');
    } on AuthException catch (e) {
      final conectado =
          e.message.toLowerCase().contains('invalid login credentials');
      _mostrar(conectado
          ? '✅ Conectado a Supabase'
          : '❌ Supabase respondió con un error: ${e.message}');
    } catch (e) {
      _mostrar('❌ No se pudo conectar: $e');
    }
  }

  void _mostrar(String texto) {
    if (mounted) setState(() => _resultado = texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          _resultado,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
