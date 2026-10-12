import 'package:flutter/material.dart';

import '../../widgets/boton_cerrar_sesion.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// Inicio del administrador.
///
/// TODO(E7): revisar verificaciones de identidad pendientes.
class AdminInicioScreen extends StatelessWidget {
  const AdminInicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaEnConstruccion(
      titulo: 'Administración',
      historia: 'E7 · Verificación y administración',
      acciones: [Text('Entraste como administrador.')],
      accionesBarra: [BotonCerrarSesion()],
    );
  }
}
