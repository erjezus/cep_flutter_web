import 'package:cep_flutter_web/screens/product_screen.dart';
import 'package:flutter/material.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';
import 'package:cep_flutter_web/screens/upload_expense_screen.dart';
import 'package:cep_flutter_web/screens/expense_list_screen.dart';
import 'package:cep_flutter_web/screens/common_summary_screen.dart';

class EventMenuScreen extends StatefulWidget {
  final int userId;
  final int eventId;
  final String eventName;

  const EventMenuScreen({
    super.key,
    required this.userId,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventMenuScreen> createState() => _EventMenuScreenState();
}

class _EventMenuScreenState extends State<EventMenuScreen> {
  String? expandedSection;

  void toggleSection(String section) {
    setState(() {
      expandedSection = expandedSection == section ? null : section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFD32F2F);
    final Color orangeColor = Colors.deepOrange;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventName),
        backgroundColor: mainColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context: context,
            icon: Icons.local_bar,
            title: "Consumiciones",
            color: mainColor,
            sectionKey: 'consumptions',
            isExpanded: expandedSection == 'consumptions',
            items: [
              _buildMenuItem(
                title: "Consumir",
                subtitle: "Registrar consumiciones",
                icon: Icons.fastfood,
                color: mainColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                title: "Mis consumiciones",
                subtitle: "Ver lo que has consumido",
                icon: Icons.receipt_long,
                color: Colors.grey[800]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsumptionScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            context: context,
            icon: Icons.receipt,
            title: "Gastos",
            color: orangeColor,
            sectionKey: 'expenses',
            isExpanded: expandedSection == 'expenses',
            items: [
              _buildMenuItem(
                title: "Registrar gasto",
                subtitle: "Registrar un gasto",
                icon: Icons.add_circle,
                color: orangeColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadExpenseScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                title: "Ver gastos",
                subtitle: "Ver gastos registrados",
                icon: Icons.table_chart,
                color: Colors.grey[800]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseListScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                title: "Resumen total",
                subtitle: "Ver gastos totales",
                icon: Icons.group,
                color: orangeColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommonSummaryScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required String sectionKey,
    required bool isExpanded,
    required List<Widget> items,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (_) => toggleSection(sectionKey),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          children: items,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
