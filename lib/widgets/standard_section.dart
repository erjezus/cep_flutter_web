import 'package:flutter/material.dart';

class StandardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final bool initiallyExpanded;
  final VoidCallback onToggle;

  const StandardSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
    required this.initiallyExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            initiallyExpanded: initiallyExpanded,
            onExpansionChanged: (_) => onToggle(),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
