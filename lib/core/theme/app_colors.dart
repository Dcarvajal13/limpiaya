import 'package:flutter/material.dart';

/// Paleta de LimpiaYa: dirección "Testimonio en movimiento".
///
/// Azul pizarra sobre un fondo azul claro, tarjetas blancas y un dorado
/// para las estrellas. Los nombres se mantienen de la paleta anterior para
/// no tocar las pantallas; cuando un nombre ya no describe el color, se
/// aclara en su comentario.
///
/// Las pantallas NUNCA escriben colores a mano (Color(0xFF...)):
/// usan AppColors o Theme.of(context).colorScheme.
abstract final class AppColors {
  // Marca
  static const primario = Color(0xFF2F4A6D); // azul pizarra
  static const primarioOscuro = Color(0xFF24395A); // franjas oscuras y pie
  static const primarioClaro = Color(0xFFD3DDEA); // selección y avatares

  /// Ocre: solo para destacar (fechas, contadores).
  static const acento = Color(0xFF9A5F17);
  static const ambar = Color(0xFFE7A93B); // estrellas

  // Contraste WCAG 2.2 (taller UX, sección 3.3).
  /// Ocre para texto normal o con texto blanco encima (5.9:1).
  static const acentoTexto = Color(0xFF8A5419);

  /// Borde de las estrellas doradas sobre blanco (criterio 1.4.11).
  static const estrellaBorde = Color(0xFF7A5410);

  // Fondos y superficies
  static const fondo = Color(0xFFE6EDF6); // azul claro de toda la app
  static const superficie = Color(0xFFFFFFFF); // tarjetas
  static const arena = Color(0xFFD9E3F0); // franjas y bloques (azul medio)
  static const borde = Color(0xFFD5DEEA); // tarjetas y divisores

  /// Borde de los campos de texto (3.6:1 sobre blanco, criterio 1.4.11).
  static const bordeCampo = Color(0xFF7D8796);
  /// Borde de botones secundarios y chips sin elegir.
  static const bordeBoton = Color(0xFFA9B4C4);
  static const arenaOscura = Color(0xFFC9D6E8); // bloques de foto
  static const seleccionSuave = Color(0xFFEEF2F7); // fila elegida
  static const fondoChat = Color(0xFFF3F6FA); // dentro de la ventana del chat

  // Texto
  static const texto = Color(0xFF1E2430);
  static const textoSecundario = Color(0xFF56607A); // 5.2:1 sobre el fondo
  static const textoSobreOscuro = Color(0xFFC9D6E8);

  /// Acento claro sobre fondos oscuros (íconos y antetítulos). Ahora es
  /// dorado; el nombre viene de la paleta verde anterior.
  static const verdeSobreOscuro = Color(0xFFF2C46B);
  static const textoSuaveSobreOscuro = Color(0xFFC9D6E8);

  // Estados (todos pasan 4.5:1 sobre su fondo de insignia)
  static const exito = Color(0xFF3F6E52);
  static const error = Color(0xFFB3193A);
  static const aviso = Color(0xFF6B4A07);
  static const deshabilitado = Color(0xFFE1E6EE);
  static const textoDeshabilitado = Color(0xFF6B7383);

  // Insignias de estado (fondo / texto)
  static const insigniaAzulFondo = Color(0xFFE6ECF3);
  static const insigniaAzulTexto = Color(0xFF2F4A6D);
  static const insigniaVerdeFondo = Color(0xFFE1EEE5);
  static const insigniaRojaFondo = Color(0xFFFBE3E7);
  static const insigniaAmbarFondo = Color(0xFFFBEBC4);
  static const insigniaGrisFondo = Color(0xFFEEF0F3);
  static const insigniaGrisTexto = Color(0xFF4A5262);
}
