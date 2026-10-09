import 'package:flutter/material.dart';

import '../../widgets/pantalla_en_construccion.dart';

/// Pantalla temporal después de iniciar sesión.
///
/// TODO(HU-02A/HU-02B): según el rol, se reemplaza por "Mis solicitudes"
/// (cliente, HU-08) o "Solicitudes disponibles" (trabajadora, HU-11).
/// TODO(HU-03): agregar el botón "Cerrar sesión".
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaEnConstruccion(
      titulo: 'Inicio',
      historia: 'HU-02A / HU-02B / HU-03',
    );
  }
}
