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
  List commonExpenses = [];
  List personalExpenses = [];
  bool expandPersonal = false;
  bool expandCommon = false;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  void fetchExpenses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/expenses?user_id=${widget.userId}&event_id=${widget.eventId}'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        commonExpenses = data.where((e) => e['is_common'] == true).toList();
        personalExpenses = data.where((e) => e['is_common'] != true).toList();
      });
    }
  }

  Future<void> deleteExpense(int id, bool isCommon) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/expenses/$id'),
    );
    if (response.statusCode == 200) {
      setState(() {
        if (isCommon) {
          commonExpenses.removeWhere((e) => e['id'] == id);
        } else {
          personalExpenses.removeWhere((e) => e['id'] == id);
        }
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
    return StandardCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        leading: e['image_path'] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            '$baseUrl/api/${e['image_path']}',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.receipt, color: mainColor),
          ),
        )
            : Icon(Icons.receipt, color: mainColor),
        title: Text(
          e['concept'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("€${e['amount']}"),
            if (e['notes'] != null && e['notes'].toString().isNotEmpty)
              Text(e['notes'], style: TextStyle(color: Colors.grey[700])),
            Text(
              e['created_at'].toString().split('T')[0],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteExpense(e['id'], e['is_common'] == true),
        ),
      ),
    );
  }

  Widget buildAccordion(String title, bool expanded, ValueChanged<bool> onToggle, List items, Color mainColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: StandardCard(
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
          children: items.map((e) => buildExpenseTile(e, mainColor)).toList(),
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
        title: const Text("Hoja de gastos",style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: personalExpenses.isEmpty && commonExpenses.isEmpty
          ? const Center(child: Text("No hay gastos registrados"))
          : ListView(
        children: [
          buildAccordion(
            "Gastos personales",
            expandPersonal,
                (value) => setState(() => expandPersonal = value),
            personalExpenses,
            mainColor,
          ),
          buildAccordion(
            "Gastos comunes",
            expandCommon,
                (value) => setState(() => expandCommon = value),
            commonExpenses,
            mainColor,
          ),
        ],
      ),
    );
  }
}
