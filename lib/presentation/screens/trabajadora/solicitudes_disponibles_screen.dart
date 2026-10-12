import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sesion_provider.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// Inicio de la trabajadora: solicitudes a las que se puede postular.
///
/// TODO(HU-11): lista de solicitudes disponibles según el Figma.
/// TODO(HU-03): botón "Cerrar sesión".
class SolicitudesDisponiblesScreen extends ConsumerWidget {
  const SolicitudesDisponiblesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';

    return PantallaEnConstruccion(
      titulo: 'Solicitudes disponibles',
      historia: 'HU-11',
      acciones: [Text('Hola, $nombre. Entraste como trabajadora.')],
    );
  }
}
