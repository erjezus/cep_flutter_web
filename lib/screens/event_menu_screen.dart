import 'package:flutter/material.dart';
import 'package:cep_flutter_web/screens/product_screen.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';
import 'package:cep_flutter_web/screens/upload_expense_screen.dart';
import 'package:cep_flutter_web/screens/expense_list_screen.dart';
import 'package:cep_flutter_web/screens/common_summary_screen.dart';
import 'package:cep_flutter_web/screens/lunch_list_screen.dart';
import 'package:cep_flutter_web/screens/create_lunch_screen.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';

class EventMenuScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int eventId;
  final String eventName;

  const EventMenuScreen({
    super.key,
    required this.userId,
    required this.userName,
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
    final Color mainColor = const Color(0xFFB71C1C);
    final Color accentColor = Colors.deepOrange;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.eventName, style: const TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Accesos directos
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Accesos directos",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildQuickAccess(
                          icon: Icons.fastfood,
                          label: "Consumir",
                          color: mainColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                eventId: widget.eventId,
                              ),
                            ),
                          ),
                        ),
                        _buildQuickAccess(
                          icon: Icons.receipt_long,
                          label: "Mis consumos",
                          color: Colors.grey[800]!,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsumptionScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                eventId: widget.eventId,
                              ),
                            ),
                          ),
                        ),
                        _buildQuickAccess(
                          icon: Icons.add_circle,
                          label: "Añadir gasto",
                          color: accentColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UploadExpenseScreen(
                                userId: widget.userId,
                                eventId: widget.eventId,
                              ),
                            ),
                          ),
                        ),
                        _buildQuickAccess(
                          icon: Icons.event_note,
                          label: "Almuerzos",
                          color: Colors.green[700]!,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LunchListScreen(
                                eventId: widget.eventId,
                                userId: widget.userId,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Secciones normales
            StandardSection(
              title: "Consumiciones",
              icon: Icons.local_bar,
              color: mainColor,
              initiallyExpanded: expandedSection == 'consumptions',
              onToggle: () => toggleSection('consumptions'),
              children: [
                _buildMenuItem(
                  title: "Consumir",
                  subtitle: "Registrar consumiciones",
                  icon: Icons.fastfood,
                  color: mainColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                        eventId: widget.eventId,
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(
                  title: "Mis consumiciones",
                  subtitle: "Ver lo que has consumido",
                  icon: Icons.receipt_long,
                  color: Colors.grey[800]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsumptionScreen(
                        userId: widget.userId,
                        userName: widget.userName,
                        eventId: widget.eventId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StandardSection(
              title: "Almuerzos",
              icon: Icons.lunch_dining,
              color: Colors.green[700]!,
              initiallyExpanded: expandedSection == 'lunches',
              onToggle: () => toggleSection('lunches'),
              children: [
                _buildMenuItem(
                  title: "Crear almuerzo",
                  subtitle: "Añadir un nuevo almuerzo",
                  icon: Icons.add,
                  color: Colors.green[700]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateLunchScreen(eventId: widget.eventId),
                    ),
                  ),
                ),
                _buildMenuItem(
                  title: "Gestionar almuerzos",
                  subtitle: "Ver y editar almuerzos existentes",
                  icon: Icons.event_note,
                  color: Colors.green[700]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LunchListScreen(
                        eventId: widget.eventId,
                        userId: widget.userId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StandardSection(
              title: "Gastos",
              icon: Icons.receipt,
              color: accentColor,
              initiallyExpanded: expandedSection == 'expenses',
              onToggle: () => toggleSection('expenses'),
              children: [
                _buildMenuItem(
                  title: "Registrar gasto",
                  subtitle: "Registrar un gasto",
                  icon: Icons.add_circle,
                  color: accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadExpenseScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(
                  title: "Ver gastos",
                  subtitle: "Ver gastos registrados",
                  icon: Icons.table_chart,
                  color: Colors.grey[800]!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseListScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  ),
                ),
                _buildMenuItem(
                  title: "Resumen total",
                  subtitle: "Ver gastos totales",
                  icon: Icons.group,
                  color: accentColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommonSummaryScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    return StandardCard(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
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

  Widget _buildQuickAccess({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
