import 'package:flutter/material.dart';

/// Paleta de LimpiaYa, igual al prototipo de Figma.
///
/// Las pantallas NUNCA escriben colores a mano (Color(0xFF...)):
/// usan AppColors o Theme.of(context).colorScheme.
abstract final class AppColors {
  // Marca
  static const primario = Color(0xFF0F5E58);
  static const primarioOscuro = Color(0xFF0B2E2B);
  static const primarioClaro = Color(0xFFDCEBE7);
  static const acento = Color(0xFFC8553D); // terracota: solo para destacar
  static const ambar = Color(0xFFE8A23A); // estrellas y botón destacado

  // Fondos y superficies
  static const fondo = Color(0xFFFAF5EC);
  static const superficie = Color(0xFFFFFFFF);
  static const arena = Color(0xFFF1E6D6);
  static const borde = Color(0xFFE6DACB);
  static const arenaOscura = Color(0xFFD8C4A9); // bloques de foto
  static const seleccionSuave = Color(0xFFF5FBF9); // fila elegida

  // Texto
  static const texto = Color(0xFF1F1A17);
  static const textoSecundario = Color(0xFF6B625A);
  static const textoSobreOscuro = Color(0xFFD9E2E0);
  static const verdeSobreOscuro = Color(0xFF9DD1C9);
  static const textoSuaveSobreOscuro = Color(0xFFCDD8D5);

  // Estados
  static const exito = Color(0xFF2E7D4F);
  static const error = Color(0xFFB3261E);
  static const aviso = Color(0xFFB26A00);
  static const deshabilitado = Color(0xFFE4DFD8);
  static const textoDeshabilitado = Color(0xFF8B837B);

  // Insignias de estado (fondo / texto)
  static const insigniaAzulFondo = Color(0xFFE1ECF5);
  static const insigniaAzulTexto = Color(0xFF245478);
  static const insigniaVerdeFondo = Color(0xFFDFF0E5);
  static const insigniaRojaFondo = Color(0xFFF8E2DF);
  static const insigniaAmbarFondo = Color(0xFFFAECD4);
  static const insigniaGrisFondo = Color(0xFFEEEAE5);
  static const insigniaGrisTexto = Color(0xFF655E57);
}
