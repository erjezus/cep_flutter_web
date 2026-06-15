import 'package:flutter/material.dart';

/// Muestra un valor numérico (normalmente un importe en euros) que "sube"
/// animadamente desde 0 hasta su valor final al aparecer o al cambiar.
///
/// Da una sensación moderna y de feedback en las cifras destacadas
/// (totales, balances, resúmenes).
class AnimatedCount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;
  final Duration duration;
  final TextAlign? textAlign;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '€',
    this.suffix = '',
    this.decimals = 2,
    this.duration = const Duration(milliseconds: 700),
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text(
          '$prefix${val.toStringAsFixed(decimals)}$suffix',
          style: style,
          textAlign: textAlign,
        );
      },
    );
  }
}

