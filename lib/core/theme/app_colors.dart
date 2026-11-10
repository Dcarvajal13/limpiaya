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

  // Correcciones de contraste WCAG 2.2 (taller UX, sección 3.3).
  /// Terracota para texto normal o con texto blanco encima (5.36:1).
  static const acentoTexto = Color(0xFFB24A33);

  /// Borde de las estrellas ámbar sobre blanco (4.40:1, criterio 1.4.11).
  static const estrellaBorde = Color(0xFFA86B12);

  // Fondos y superficies
  static const fondo = Color(0xFFFAF5EC);
  static const superficie = Color(0xFFFFFFFF);
  static const arena = Color(0xFFF1E6D6);
  static const borde = Color(0xFFE6DACB); // tarjetas y divisores

  /// Borde de los campos de texto (3.37:1, criterio 1.4.11). El borde de
  /// tarjetas (1.38:1) no alcanzaba para un control que hay que encontrar.
  static const bordeCampo = Color(0xFF958A80);
  static const arenaOscura = Color(0xFFD8C4A9); // bloques de foto
  static const seleccionSuave = Color(0xFFF5FBF9); // fila elegida

  // Texto
  static const texto = Color(0xFF1F1A17);
  static const textoSecundario = Color(0xFF6B625A);
  static const textoSobreOscuro = Color(0xFFD9E2E0);
  static const verdeSobreOscuro = Color(0xFF9DD1C9);
  static const textoSuaveSobreOscuro = Color(0xFFCDD8D5);

  // Estados
  // exito y aviso se oscurecieron para pasar 4.5:1 en sus insignias
  // (antes #2E7D4F con 4.26:1 y #B26A00 con 3.64:1; taller UX, 3.3).
  static const exito = Color(0xFF23683F);
  static const error = Color(0xFFB3261E);
  static const aviso = Color(0xFF8A5300);
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
