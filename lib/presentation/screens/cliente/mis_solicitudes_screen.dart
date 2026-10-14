import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/boton_cerrar_sesion.dart';
import '../../widgets/pantalla_en_construccion.dart';

/// Inicio del cliente: sus solicitudes.
///
/// TODO(HU-08): lista de solicitudes del cliente según el Figma.
/// HU-05: desde acá se completa el perfil (zona y dirección).
class MisSolicitudesScreen extends ConsumerWidget {
  const MisSolicitudesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nombre = ref.watch(sesionProvider).value?.nombre ?? '';
    final completo = ref.watch(sesionProvider).value?.perfilCompleto ?? false;

    return PantallaEnConstruccion(
      titulo: 'Mis solicitudes',
      historia: 'HU-08',
      acciones: [
        Text('Hola, $nombre. Entraste como cliente.'),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(Rutas.perfilCliente),
          child: Text(completo ? 'Editar mi perfil' : 'Completar mi perfil'),
        ),
      ],
      accionesBarra: const [BotonCerrarSesion()],
    );
  }
}
