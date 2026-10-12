import 'package:flutter/material.dart';

/// Campo de texto con la etiqueta arriba, como en el Figma.
///
/// Se usa igual que un TextFormField:
///   CampoTexto(
///     etiqueta: 'Correo',
///     pista: 'tu@correo.com',
///     controller: _email,
///     validator: Validadores.email,
///   )
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    this.pista,
    this.ayuda,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.sufijo,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final String etiqueta;

  /// Texto gris dentro del campo vacío (hint).
  final String? pista;

  /// Texto pequeño debajo del campo (por ejemplo "Mínimo 8 caracteres").
  final String? ayuda;

  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;

  /// Ícono a la derecha dentro del campo (por ejemplo, el ojo de la contraseña).
  final Widget? sufijo;

  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(etiqueta, style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 7),
        Semantics(
          label: etiqueta,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            onFieldSubmitted: onFieldSubmitted,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: pista,
              helperText: ayuda,
              suffixIcon: sufijo,
            ),
          ),
        ),
      ],
    );
  }
}
