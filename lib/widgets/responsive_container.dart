import 'package:flutter/material.dart';

/// Centra y limita el ancho del contenido para que la app se vea bien
/// tanto en móvil (ocupa todo el ancho) como en web/escritorio
/// (queda centrada y legible, sin estirarse de borde a borde).
///
/// Uso típico:
/// ```dart
/// body: ResponsiveContainer(child: ListView(...)),
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 700,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

