import 'package:flutter/material.dart';

/// Pantalla temporal para las rutas cuya historia aún no se ha hecho.
/// Quien tome la historia reemplaza este widget por la pantalla real.
class PantallaEnConstruccion extends StatelessWidget {
  const PantallaEnConstruccion({
    super.key,
    required this.titulo,
    required this.historia,
    this.acciones = const [],
  });

  final String titulo;

  /// Código de la tarjeta de Trello, por ejemplo 'HU-01'.
  final String historia;

  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 16),
              Text(titulo, style: textos.headlineSmall),
              const SizedBox(height: 8),
              Text('Pendiente: $historia', style: textos.bodyMedium),
              const SizedBox(height: 24),
              ...acciones,
            ],
          ),
        ),
      ),
    );
  }
}
