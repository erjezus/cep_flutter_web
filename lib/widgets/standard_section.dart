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
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            initiallyExpanded: initiallyExpanded,
            onExpansionChanged: (_) => onToggle(),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}
