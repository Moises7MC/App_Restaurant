import 'package:flutter/material.dart';

/// Clase que contiene todos los colores usados en la app
/// Basados en el diseño de las capturas proporcionadas
class AppColors {
  // Color principal - Amarillo dorado
  static const Color primary = Color(0xFFFFC107);
  static const Color primaryLight = Color(0xFFFFD54F);
  static const Color primaryDark = Color(0xFFFFA000);

  // Fondos
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Textos
  static const Color textPrimary = Color(0xFF1E3A5F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Otros
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  // static const Color warning = Color(
  //   0xFFFFC107,
  // ); // Amarillo - mismo que primary
  static const Color warning = Color.fromARGB(255, 255, 179, 0);
  // static const Color warning = Color(0xFFFFA000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Sombras y bordes
  static const Color shadow = Color(0x1A000000);
  static const Color border = Color(0xFFE0E0E0);
}
