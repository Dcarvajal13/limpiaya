import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sesion_provider.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// Inicio del cliente: sus solicitudes.
///
/// TODO(HU-08): lista de solicitudes del cliente según el Figma.
/// TODO(HU-03): botón "Cerrar sesión".
class MisSolicitudesScreen extends ConsumerWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';

    return PantallaEnConstruccion(
      titulo: 'Mis solicitudes',
      historia: 'HU-08',
      acciones: [Text('Hola, $nombre. Entraste como cliente.')],
    );
  }
}
