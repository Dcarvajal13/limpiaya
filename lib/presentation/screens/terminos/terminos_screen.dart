import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/contenido_centrado.dart';
import '../../widgets/desplazable_con_pie.dart';
import '../../widgets/logo_limpiaya.dart';

/// Términos y condiciones de LimpiaYa, con la política de privacidad al
/// final ('/terminos', y '/terminos?seccion=privacidad' baja directo a ella).
///
/// Se ve igual con o sin sesión (Rutas.libres). En escritorio, a la
/// izquierda va el índice y a la derecha el texto.
class TerminosScreen extends StatefulWidget {
  const TerminosScreen({super.key, this.seccion});

  /// Id de la sección a la que se baja al abrir (por ejemplo 'privacidad').
  final String? seccion;

  static const actualizacion = '12 de noviembre de 2026';

  @override
  State<TerminosScreen> createState() => _TerminosScreenState();
}

class _TerminosScreenState extends State<TerminosScreen> {
  late final _claves = {
    for (final s in _secciones) s.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final destino = widget.seccion;
    if (destino != null && _claves.containsKey(destino)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irA(destino));
    }
  }

  void _irA(String id) {
    final contexto = _claves[id]?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Rutas.landing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movil = Responsive.esMovil(context);
    final textos = Theme.of(context).textTheme;

    final encabezado = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Términos y condiciones',
          style: (movil ? textos.headlineLarge : textos.displaySmall)
              ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.texto),
        ),
        const SizedBox(height: 8),
        Text(
          'Última actualización: ${TerminosScreen.actualizacion}',
          style: textos.bodyMedium?.copyWith(color: AppColors.textoSecundario),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.insigniaAmbarFondo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.aviso),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Al crear una cuenta o usar LimpiaYa aceptas estos términos. '
                  'Léelos con calma: explican qué hace LimpiaYa, qué se espera '
                  'de clientes y trabajadoras, y cómo cuidamos tus datos.',
                  style: textos.bodyMedium?.copyWith(color: AppColors.texto),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in _secciones.indexed)
          _BloqueSeccion(
            key: _claves[s.id],
            numero: i + 1,
            seccion: s,
          ),
      ],
    );

    final indice = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CONTENIDO',
            style: textos.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          for (final (i, s) in _secciones.indexed)
            InkWell(
              onTap: () => _irA(s.id),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  '${i + 1}. ${s.titulo}',
                  style: textos.bodySmall?.copyWith(color: AppColors.texto),
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Volver',
          onPressed: _volver,
        ),
        title: const LogoLimpiaYa(tamano: 32),
      ),
      body: DesplazableConPie(
        child: ContenidoCentrado(
          vertical: movil ? 24 : 40,
          child: movil
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [encabezado, const SizedBox(height: 24), texto],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: indice),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          encabezado,
                          const SizedBox(height: 32),
                          texto,
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BloqueSeccion extends StatelessWidget {
  const _BloqueSeccion({
    super.key,
    required this.numero,
    required this.seccion,
  });

  final int numero;
  final _Seccion seccion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final cuerpo = textos.bodyLarge?.copyWith(
      color: AppColors.texto,
      height: 1.55,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$numero. ${seccion.titulo}',
            style: textos.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primarioOscuro,
            ),
          ),
          const SizedBox(height: 10),
          for (final parrafo in seccion.parrafos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: parrafo.startsWith('• ')
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(parrafo, style: cuerpo),
                    )
                  : Text(parrafo, style: cuerpo),
            ),
        ],
      ),
    );
  }
}

class _Seccion {
  const _Seccion(this.id, this.titulo, this.parrafos);

  final String id;
  final String titulo;
  final List<String> parrafos;
}

final _porcentaje = (AppConstants.comisionLimpiaYa * 100).round();

final _secciones = <_Seccion>[
  const _Seccion('que-es', 'Qué es LimpiaYa', [
    'LimpiaYa es una plataforma web que conecta a personas que necesitan '
        'limpieza en su casa ("clientes") con trabajadoras de limpieza '
        'independientes ("trabajadoras") en zonas de Caracas.',
    'LimpiaYa no es empleador de las trabajadoras ni presta el servicio de '
        'limpieza: ofrece las herramientas para publicar solicitudes, '
        'postularse, elegir, coordinar por chat y calificar.',
  ]),
  const _Seccion('cuenta', 'Tu cuenta', [
    '• Debes ser mayor de 18 años para registrarte.',
    '• Los datos que registras (nombre, teléfono, zona) deben ser reales y '
        'estar al día.',
    '• Tu cuenta es personal: no la compartas ni le des tu contraseña a '
        'nadie. Eres responsable de lo que se haga con ella.',
    '• Puedes tener una sola cuenta por persona, como cliente o como '
        'trabajadora.',
  ]),
  const _Seccion('verificacion', 'Verificación de identidad', [
    'Antes de postularse, cada trabajadora debe verificar su identidad con '
        'una foto de su cédula y una selfie. El equipo de LimpiaYa las revisa '
        'y aprueba o rechaza la verificación.',
    'La verificación reduce riesgos, pero no es una garantía absoluta. Revisa '
        'también las reseñas y el perfil antes de elegir.',
  ]),
  const _Seccion('servicio', 'Solicitudes, postulaciones y servicios', [
    '• El cliente publica una solicitud con fecha, hora, horas estimadas, '
        'tipo de limpieza, zona y pago ofrecido.',
    '• Las trabajadoras de esa zona pueden postularse. El cliente elige a una '
        'y la solicitud queda asignada.',
    '• La dirección exacta del cliente solo la ve la trabajadora elegida. '
        'Las demás solo ven la zona.',
    '• Cliente y trabajadora se comprometen a cumplir el horario y lo '
        'acordado en la solicitud.',
  ]),
  _Seccion('pagos', 'Pagos y tarifa', [
    'El cliente decide cuánto ofrece por el servicio y lo paga directamente '
        'a la trabajadora por Pago Móvil, transferencia o efectivo, en dólares '
        'o bolívares.',
    'Al cliente se le muestra, antes de publicar, una tarifa de servicio de '
        'LimpiaYa del $_porcentaje % sobre el pago ofrecido. Para la '
        'trabajadora, LimpiaYa es gratis: recibe completo el monto publicado.',
  ]),
  const _Seccion('cancelaciones', 'Cancelaciones', [
    'Cualquiera de las dos partes puede cancelar un servicio asignado. Si se '
        'cancela con menos de 24 horas de anticipación, se registra como '
        'cancelación tardía y puede afectar la reputación y el nivel de quien '
        'cancela.',
  ]),
  const _Seccion('resenas', 'Calificaciones y reseñas', [
    'Al terminar un servicio, cliente y trabajadora se califican. Las reseñas '
        'deben ser honestas y respetuosas, y referirse solo al servicio.',
    'LimpiaYa puede ocultar reseñas con insultos, datos personales o '
        'contenido que no tenga que ver con el servicio.',
  ]),
  const _Seccion('chat', 'Comunicación', [
    'Toda la coordinación se hace por el chat de LimpiaYa. La plataforma no '
        'muestra teléfonos ni correos entre cliente y trabajadora, para '
        'proteger a las dos partes.',
  ]),
  const _Seccion('conducta', 'Normas de convivencia', [
    '• Trata a todas las personas con respeto. No se permiten insultos, '
        'acoso ni discriminación de ningún tipo.',
    '• No publiques solicitudes falsas ni uses la plataforma para fines '
        'distintos a la limpieza del hogar.',
    '• LimpiaYa puede suspender o cerrar cuentas que incumplan estas normas.',
  ]),
  const _Seccion('responsabilidad', 'Responsabilidad', [
    'LimpiaYa facilita el contacto entre clientes y trabajadoras, pero no '
        'controla cómo se presta cada servicio. No respondemos por daños, '
        'pérdidas o acuerdos hechos fuera de la plataforma.',
    'Si ocurre un problema durante un servicio, repórtalo y califica con '
        'sinceridad para que otras personas estén informadas.',
  ]),
  const _Seccion('privacidad', 'Política de privacidad', [
    'Datos que guardamos: nombre, correo, teléfono, rol, zonas, direcciones '
        'que guardes, solicitudes, mensajes del chat, reseñas y, en el caso de '
        'las trabajadoras, las fotos de verificación.',
    '• Tu correo y tu teléfono no se muestran a otros usuarios.',
    '• Tu dirección exacta y tus direcciones guardadas solo las ves tú, y la '
        'dirección de una solicitud solo la ve la trabajadora que eliges.',
    '• Las fotos de la cédula y la selfie solo las ve el equipo que revisa '
        'la verificación.',
    '• No vendemos ni compartimos tus datos con terceros para publicidad.',
    'Puedes pedir que corrijamos o borremos tus datos escribiéndole al '
        'equipo de LimpiaYa.',
  ]),
  const _Seccion('cambios', 'Cambios a estos términos', [
    'Podemos actualizar estos términos. Cuando haya cambios importantes lo '
        'avisaremos en la plataforma, y la fecha de arriba mostrará la última '
        'actualización.',
    'LimpiaYa es un proyecto académico de Ingeniería de Software de la '
        'Universidad Metropolitana (UNIMET), Caracas.',
  ]),
];
