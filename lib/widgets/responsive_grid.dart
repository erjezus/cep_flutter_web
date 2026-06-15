import 'package:flutter/material.dart';

/// Coloca [children] en una sola columna en móvil y en varias columnas
/// en pantallas anchas (web/escritorio), aprovechando el ancho disponible
/// sin estirar las tarjetas de borde a borde.
///
/// En pantallas estrechas se comporta como una columna normal; al superar
/// [breakpoint] reparte los elementos en 2-3 columnas según el ancho.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final double minColumnWidth;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.breakpoint = 800,
    this.spacing = 16,
    this.minColumnWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= breakpoint) {
          columns = (width / minColumnWidth).floor().clamp(1, 3);
        }

        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

