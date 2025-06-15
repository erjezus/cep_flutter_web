import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class ExpenseListScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const ExpenseListScreen({required this.userId, required this.eventId, super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  Map<String, List> expensesByType = {};
  Map<String, bool> expandedTypes = {};
  final baseUrl = AppConfig.baseUrl;

  final List<String> fixedTypeOrder = ['Común', 'Comida', 'Bebida', 'A cuenta', 'Otro'];
  bool onlyMine = false;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  void fetchExpenses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/expenses?eventId=${widget.eventId}'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final filtered = onlyMine ? data.where((e) => e['user_id'] == widget.userId).toList() : data;

      final Map<String, List> grouped = {};
      for (var e in filtered) {
        final type = e['expense_type'] ?? 'Otro';
        if (!grouped.containsKey(type)) {
          grouped[type] = [];
        }
        grouped[type]!.add(e);
      }

      setState(() {
        expensesByType = grouped;
        expandedTypes = {for (var k in grouped.keys) k: false};
      });
    }
  }

  Future<void> deleteExpense(int id, String type) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/expenses/$id'),
    );
    if (response.statusCode == 200) {
      setState(() {
        expensesByType[type]?.removeWhere((e) => e['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gasto eliminado"),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Widget buildExpenseTile(dynamic e, Color mainColor) {
    final imagePath = e['image_path'];
    final hasImage = imagePath != null && imagePath.toString().isNotEmpty;

    final concept = e['concept'] ?? '';
    final amount = e['amount']?.toStringAsFixed(2) ?? '';
    final user = e['user_name'] ?? '';
    final notes = e['notes'] ?? '';
    final date = (e['created_at'] ?? '').toString().split('T')[0];

    return StandardCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  concept,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => deleteExpense(e['id'], e['expense_type']),
                tooltip: 'Eliminar gasto',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(user, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Icon(Icons.euro_symbol, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text("€$amount", style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          if (notes.toString().isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 14, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          if (hasImage)
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ListTile(
                leading: Icon(Icons.image, color: mainColor),
                title: Text(
                  'Ver imagen',
                  style: TextStyle(color: mainColor, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text("No se pudo cargar la imagen"),
                      ),
                    ),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAccordion(
      String title,
      bool expanded,
      ValueChanged<bool> onToggle,
      List items,
      Color mainColor,
      ) {
    final double total = items.fold<double>(
      0.0,
          (sum, item) => sum + (double.tryParse(item['amount'].toString()) ?? 0.0),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: StandardCard(
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: mainColor),
          ),
          children: [
            ...items.map((e) => buildExpenseTile(e, mainColor)).toList(),
            const Divider(),
            ListTile(
              title: const Text("Total"),
              trailing: Text(
                "€${total.toStringAsFixed(2)}",
                style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hoja de gastos", style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SwitchListTile(
            value: onlyMine,
            onChanged: (value) {
              setState(() {
                onlyMine = value;
              });
              fetchExpenses();
            },
            title: const Text("Ver solo mis gastos"),
            activeColor: mainColor,
          ),
          Expanded(
            child: expensesByType.isEmpty
                ? const Center(child: Text("No hay gastos registrados"))
                : ListView(
              children: [
                for (var type in fixedTypeOrder)
                  if (expensesByType.containsKey(type))
                    buildAccordion(
                      type,
                      expandedTypes[type] ?? false,
                          (value) => setState(() => expandedTypes[type] = value),
                      expensesByType[type]!,
                      mainColor,
                    ),
                for (var type in expensesByType.keys)
                  if (!fixedTypeOrder.contains(type))
                    buildAccordion(
                      type,
                      expandedTypes[type] ?? false,
                          (value) => setState(() => expandedTypes[type] = value),
                      expensesByType[type]!,
                      mainColor,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}