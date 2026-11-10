import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validadores.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/estrellas.dart';
import '../../widgets/insignia_estado.dart';
import '../../widgets/insignia_verificada.dart';
import '../../widgets/logo_limpiaya.dart';

/// Catálogo visual del sistema de diseño (ruta /diseno).
///
/// Sirve para ver de un vistazo cómo se ven los componentes compartidos y
/// copiar el código de ejemplo. No es parte del producto final.
class SistemaDisenoScreen extends StatefulWidget {
  const SistemaDisenoScreen({super.key});

  @override
  State<SistemaDisenoScreen> createState() => _SistemaDisenoScreenState();
}

class _SistemaDisenoScreenState extends State<SistemaDisenoScreen> {
  String _tipoSeleccionado = 'General';
  int _estrellas = 4;

  static const _colores = <(String, Color)>[
    ('primario', AppColors.primario),
    ('primarioOscuro', AppColors.primarioOscuro),
    ('primarioClaro', AppColors.primarioClaro),
    ('fondo', AppColors.fondo),
    ('arena', AppColors.arena),
    ('acento', AppColors.acento),
    ('acentoTexto', AppColors.acentoTexto),
    ('ambar', AppColors.ambar),
    ('estrellaBorde', AppColors.estrellaBorde),
    ('texto', AppColors.texto),
    ('textoSecundario', AppColors.textoSecundario),
    ('borde', AppColors.borde),
    ('bordeCampo', AppColors.bordeCampo),
    ('exito', AppColors.exito),
    ('error', AppColors.error),
    ('aviso', AppColors.aviso),
  ];

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const LogoLimpiaYa(tamano: 32)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        children: [
          ContenidoCentrado(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sistema de diseño', style: textos.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Colores, tipografías y componentes de LimpiaYa. '
                  'Úsalos siempre en vez de crear estilos nuevos.',
                  style: textos.bodyLarge,
                ),
                _Seccion(
                  titulo: 'Colores · AppColors',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (nombre, color) in _colores)
                        _Muestra(nombre: nombre, color: color),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Tipografía · Theme.of(context).textTheme',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('displayLarge · Bricolage', style: textos.displayLarge),
                      Text('headlineLarge · títulos de página', style: textos.headlineLarge),
                      Text('titleLarge · títulos de tarjeta', style: textos.titleLarge),
                      Text('bodyLarge · subtítulos y párrafos destacados', style: textos.bodyLarge),
                      Text('bodyMedium · texto normal en Figtree', style: textos.bodyMedium),
                      Text('bodySmall · texto secundario', style: textos.bodySmall),
                      Text('labelLarge · botones', style: textos.labelLarge),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Botones',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(onPressed: () {}, child: const Text('FilledButton')),
                      OutlinedButton(onPressed: () {}, child: const Text('OutlinedButton')),
                      TextButton(onPressed: () {}, child: const Text('TextButton')),
                      FilledButton(
                        style: AppTheme.botonAmbar,
                        onPressed: () {},
                        child: const Text('AppTheme.botonAmbar'),
                      ),
                      FilledButton(
                        style: AppTheme.botonPeligro,
                        onPressed: () {},
                        child: const Text('AppTheme.botonPeligro'),
                      ),
                      const FilledButton(onPressed: null, child: Text('Deshabilitado')),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Con ícono'),
                      ),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Campos de texto · CampoTexto (etiqueta arriba, como el Figma)',
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      const SizedBox(
                        width: 320,
                        child: CampoTexto(
                          etiqueta: 'Correo',
                          pista: 'tu@correo.com',
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            hintText: 'tucorreo@gmail.com',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 320,
                        child: TextFormField(
                          initialValue: '0414123',
                          autovalidateMode: AutovalidateMode.always,
                          validator: Validadores.telefono,
                          decoration: const InputDecoration(labelText: 'Teléfono (con error)'),
                        ),
                      ),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Chips · ChoiceChip',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tipo in const ['General', 'Profunda', 'Post-mudanza', 'Planchado'])
                        ChoiceChip(
                          label: Text(tipo),
                          selected: _tipoSeleccionado == tipo,
                          onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
                        ),
                    ],
                  ),
                ),
                const _Seccion(
                  titulo: 'Insignias · InsigniaEstado / InsigniaVerificada',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InsigniaEstado('Publicada', tono: TonoInsignia.azul),
                      InsigniaEstado('Asignada', tono: TonoInsignia.verde),
                      InsigniaEstado('Completada', tono: TonoInsignia.gris),
                      InsigniaEstado('Cancelada', tono: TonoInsignia.rojo),
                      InsigniaEstado('Pendiente', tono: TonoInsignia.ambar),
                      InsigniaVerificada(),
                    ],
                  ),
                ),
                _Seccion(
                  titulo: 'Avatar y estrellas',
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const AvatarUsuario(nombre: 'Carmen Pérez'),
                      const AvatarUsuario(nombre: 'María Alejandra', tamano: 64),
                      const Estrellas(valor: 4.6),
                      Estrellas(
                        valor: _estrellas.toDouble(),
                        tamano: 32,
                        onChanged: (v) => setState(() => _estrellas = v),
                      ),
                    ],
                  ),
                ),
                const _Seccion(
                  titulo: 'Tarjeta · Card',
                  child: SizedBox(
                    width: 380,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InsigniaEstado('Publicada', tono: TonoInsignia.azul),
                            SizedBox(height: 12),
                            Text('Limpieza general'),
                            Text('Sáb 17 oct · 8:00 a. m. · 5 horas · Los Palos Grandes'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const _Seccion(
                  titulo: 'Estado vacío · EstadoVacio',
                  child: Card(
                    child: EstadoVacio(
                      icono: Icons.inbox_outlined,
                      titulo: 'Aún no tienes solicitudes',
                      mensaje: 'Cuando publiques una, aparecerá aquí.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra({required this.nombre, required this.color});

  final String nombre;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borde),
            ),
          ),
          const SizedBox(height: 6),
          Text(nombre, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
