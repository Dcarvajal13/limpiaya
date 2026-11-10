import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';

/// HU-40 c2 · Aviso de "Aún no verificas tu correo" con el botón
/// "Reenviar correo".
///
/// Sale en el login cuando alguien intenta entrar sin haber confirmado su
/// correo, y en la pantalla "Revisa tu correo" después de registrarse.
class AvisoVerificarCorreo extends ConsumerStatefulWidget {
  const AvisoVerificarCorreo({
    super.key,
    required this.email,
    this.titulo = 'Aún no verificas tu correo',
  });

  final String email;
  final String titulo;

  @override
  ConsumerState<AvisoVerificarCorreo> createState() =>
      _AvisoVerificarCorreoState();
}

class _AvisoVerificarCorreoState extends ConsumerState<AvisoVerificarCorreo> {
  bool _enviando = false;
  bool _enviado = false;
  String? _error;

  Future<void> _reenviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(verificacionCorreoRepositoryProvider).reenviar(widget.email);
      if (!mounted) return;
      setState(() => _enviado = true);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'No pudimos reenviar el correo. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('aviso-verificar-correo'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.insigniaAmbarFondo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 22,
                  color: AppColors.aviso,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: textos.titleSmall?.copyWith(
                          color: AppColors.aviso,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Te enviamos un enlace a '),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(
                              text: '. Ábrelo para activar tu cuenta. Si no '
                                  'lo ves, revisa la carpeta de spam.',
                            ),
                          ],
                        ),
                        style: textos.bodySmall?.copyWith(
                          color: AppColors.texto,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('reenviar-correo'),
                  onPressed: _enviando ? null : _reenviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(_enviado ? 'Reenviar otra vez' : 'Reenviar correo'),
                ),
                if (_enviado && _error == null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.exito,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Te enviamos otro correo.',
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.exito,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                key: const Key('error-reenviar'),
                style: textos.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
