import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';

/// Estilo unificado de notificaciones (SnackBars) para toda la app.
///
/// Antes había mezcla: unos flotantes y otros pegados abajo, con colores
/// distintos. Ahora todos son flotantes, redondeados y con icono de
/// éxito / error / info para una experiencia coherente.
class AppSnackBar {
  AppSnackBar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.positive, Icons.check_circle_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.negative, Icons.error_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, Colors.grey.shade800, Icons.info_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        elevation: 4,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

