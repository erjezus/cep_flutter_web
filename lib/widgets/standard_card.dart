import 'package:flutter/material.dart';

class StandardCard extends StatelessWidget {
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const StandardCard({
    super.key,
    required this.child,
    this.elevation = 4,
    this.padding = const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: elevation,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
