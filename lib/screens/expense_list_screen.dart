import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/app_dialog.dart';

class ExpenseListScreen extends StatefulWidget {
  final int userId;
  final int eventId;
  final bool initialUnpaidOnly;

  const ExpenseListScreen({
    required this.userId,
    required this.eventId,
    this.initialUnpaidOnly = false,
    super.key,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  Map<String, List> expensesByType = {};
  Map<String, bool> expandedTypes = {};
  final baseUrl = AppConfig.baseUrl;

  final List<String> fixedTypeOrder = ['Común', 'Comida', 'Bebida', 'A cuenta', 'Otro'];
  bool onlyMine = false;
  bool onlyUnpaid = false;

  /// Normaliza el campo `paid` que puede llegar como bool, num o string.
  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  /// Color asociado a cada tipo de gasto.
  Color _typeColor(String type) {
    switch (type) {
      case 'Bebida':
        return AppColors.primary;
      case 'Comida':
        return AppColors.food;
      case 'Común':
        return AppColors.common;
      case 'A cuenta':
        return AppColors.blue;
      case 'Almuerzo':
        return AppColors.lunch;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  void initState() {
    super.initState();
    onlyUnpaid = widget.initialUnpaidOnly;
    fetchExpenses();
  }

  void fetchExpenses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/expenses?eventId=${widget.eventId}'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      var filtered = onlyMine
          ? data.where((e) => e['user_id'] == widget.userId).toList()
          : data;
      if (onlyUnpaid) {
        filtered = filtered.where((e) => !_asBool(e['paid'])).toList();
      }

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
    final confirmed = await AppDialog.confirm(
      context,
      title: "¿Eliminar gasto?",
      message: "Esta acción no se puede deshacer.",
      confirmLabel: "Eliminar",
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/expenses/$id'),
    );
    if (response.statusCode == 200) {
      setState(() {
        expensesByType[type]?.removeWhere((e) => e['id'] == id);
      });
      AppSnackBar.success(context, "Gasto eliminado");
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
    final Color typeColor = _typeColor(title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: StandardCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
          ),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "€${total.toStringAsFixed(2)}",
                  style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            ...items.map((e) => buildExpenseTile(e, typeColor)).toList(),
            const Divider(),
            ListTile(
              title: const Text("Total"),
              trailing: Text(
                "€${total.toStringAsFixed(2)}",
                style: TextStyle(
                  color: typeColor,
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
    final mainColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hoja de gastos"),
      ),
      body: ResponsiveContainer(
        child: Column(
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
            SwitchListTile(
              value: onlyUnpaid,
              onChanged: (value) {
                setState(() {
                  onlyUnpaid = value;
                });
                fetchExpenses();
              },
              title: const Text("Ver solo gastos sin pagar"),
              activeColor: mainColor,
            ),
            Expanded(
              child: expensesByType.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long,
                      title: "No hay gastos registrados",
                      message: "Los gastos que se añadan aparecerán agrupados por tipo aquí.",
                    )
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
      ),
    );
  }
}