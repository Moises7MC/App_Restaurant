import 'package:flutter/material.dart';

/// Paleta de colores específica del cantador
/// (basada en el mockup: amber para entradas, teal para segundos, violeta para "Para llevar")
class CantadorColors {
  // Color principal del cantador
  static const Color primary = Color(0xFF7c3aed); // violeta

  // Entradas (amber/dorado)
  static const Color entradaBg = Color(0xFFFAEEDA);
  static const Color entradaBorder = Color(0xFFEF9F27);
  static const Color entradaCircle = Color(0xFFBA7517);
  static const Color entradaTextDark = Color(0xFF412402);
  static const Color entradaTextMid = Color(0xFF633806);
  static const Color entradaTextLight = Color(0xFF854F0B);

  // Segundos (teal/verde)
  static const Color segundoBg = Color(0xFFE1F5EE);
  static const Color segundoCircle = Color(0xFF1D9E75);
  static const Color segundoTextDark = Color(0xFF04342C);
  static const Color segundoTextMid = Color(0xFF0F6E56);

  // Para llevar (morado claro)
  static const Color paraLlevarBg = Color(0xFFEEEDFE);
  static const Color paraLlevarText = Color(0xFF3C3489);

  // Cancelado (rojo claro)
  static const Color canceladoBg = Color(0xFFFCEBEB);
  static const Color canceladoText = Color(0xFF791F1F);

  // Cronómetros
  static const Color tiempoVerde = Color(0xFF1D9E75);
  static const Color tiempoNaranja = Color(0xFFEF9F27);
  static const Color tiempoRojo = Color(0xFFD32F2F);
}
