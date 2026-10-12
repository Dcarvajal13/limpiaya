import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import 'widgets/barra_visitante.dart';
import 'widgets/seccion_confianza.dart';
import 'widgets/seccion_final.dart';
import 'widgets/seccion_hero.dart';
import 'widgets/seccion_pasos.dart';
import 'widgets/seccion_precio.dart';
import 'widgets/seccion_preguntas.dart';
import 'widgets/seccion_testimonios.dart';
import 'widgets/seccion_trabajadoras.dart';
import 'widgets/seccion_zonas.dart';

/// Página de inicio para visitantes (HU-62).
///
/// Cuenta qué es LimpiaYa y cómo funciona, y lleva al registro (HU-01)
/// o al inicio de sesión (HU-02A / HU-02B). Si ya hay sesión, el router
/// manda directo al inicio y esta pantalla no se ve (criterio 4).
///
/// Cada sección está en su propio archivo dentro de `widgets/`.
/// Es solo presentación: no habla con Supabase.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _desplazamiento = ScrollController();

  /// Marcas para poder saltar a cada sección desde la barra de arriba.
  final _secciones = {
    for (final destino in DestinoLanding.values) destino: GlobalKey(),
  };

  static const _duracion = Duration(milliseconds: 500);

  @override
  void dispose() {
    _desplazamiento.dispose();
    super.dispose();
  }

  void _irA(DestinoLanding destino) {
    final contexto = _secciones[destino]!.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(contexto, duration: _duracion, curve: Curves.easeInOut);
  }

  void _irArriba() {
    if (!_desplazamiento.hasClients) return;
    _desplazamiento.animateTo(0, duration: _duracion, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BarraVisitante(
        alto: Responsive.esMovil(context) ? 68 : 80,
        onIrA: _irA,
        onLogo: _irArriba,
      ),
      body: SingleChildScrollView(
        controller: _desplazamiento,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SeccionHero(),
            SeccionPasos(key: _secciones[DestinoLanding.comoFunciona]),
            const SeccionTrabajadoras(),
            SeccionConfianza(key: _secciones[DestinoLanding.confianza]),
            SeccionPrecio(key: _secciones[DestinoLanding.precio]),
            const SeccionZonas(),
            const SeccionTestimonios(),
            SeccionPreguntas(key: _secciones[DestinoLanding.preguntas]),
            const SeccionFinal(),
            PiePagina(onLogo: _irArriba),
          ],
        ),
      ),
    );
  }
}
