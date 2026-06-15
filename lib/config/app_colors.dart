import 'package:flutter/material.dart';

/// Paleta de colores centralizada de la app "El Perolón".
///
/// Antes existían dos rojos distintos repartidos por las pantallas
/// (`0xFFB71C1C` y `0xFFD32F2F`). Ahora todo usa [AppColors.primary]
/// para garantizar coherencia visual en móvil y web.
class AppColors {
  AppColors._();

  /// Color principal de marca (AppBars, botones, acentos).
  static const Color primary = Color(0xFFD32F2F);

  /// Variante oscura, usada en degradados (p. ej. el login).
  static const Color primaryDark = Color(0xFFB71C1C);

  /// Fondo claro estándar de las pantallas con listas.
  static const Color scaffoldBackground = Color(0xFFF5F5F5);

  // --- Colores semánticos por categoría (se mantienen diferenciados) ---
  static const Color food = Colors.deepOrange;
  static final Color lunch = Colors.green.shade700;
  static const Color users = Colors.indigo;
  static const Color prices = Colors.teal;
  static final Color expenses = Colors.orange.shade800;
  static final Color common = Colors.purple.shade700;
  static final Color blue = Colors.blue.shade700;

  // --- Estados ---
  static final Color positive = Colors.green.shade700;
  static final Color negative = Colors.red.shade700;
}

