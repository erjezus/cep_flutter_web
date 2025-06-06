import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/screens/upload_lunch_expense_screen.dart';

class LunchExpenseListScreen extends StatefulWidget {
  final int lunchId;
  final int userId;
  final int eventId;

  const LunchExpenseListScreen({
    required this.lunchId,
    required this.userId,
    required this.eventId,
    super.key,
  });

  @override
  State<LunchExpenseListScreen> createState() => _LunchExpenseListScreenState();
}

class _LunchExpenseListScreenState extends State<LunchExpenseListScreen> {
  List expenses = [];
  bool isLoading = false;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/api/lunches/expenses?lunchId=${widget.lunchId}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          expenses = data is List ? data : [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar gastos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de red o de formato')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteExpense(int id) async {
    final unlinkUrl = Uri.parse('$baseUrl/api/expense_lunch?expense_id=$id&lunch_id=${widget.lunchId}');
    final unlinkRes = await http.delete(unlinkUrl);

    if (unlinkRes.statusCode != 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al desasociar gasto del almuerzo"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await http.delete(Uri.parse('$baseUrl/api/expenses/$id'));

    if (response.statusCode == 200) {
      setState(() {
        expenses.removeWhere((e) => e['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gasto eliminado"),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al eliminar el gasto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadLunchExpenseScreen(
          userId: widget.userId,
          eventId: widget.eventId,
          lunchId: widget.lunchId,
        ),
      ),
    );
    if (result == true) fetchExpenses();
  }

  Widget buildExpenseTile(dynamic e, Color mainColor) {
    final imagePath = e['image_path'];
    final hasImage = imagePath != null && imagePath.toString().isNotEmpty;

    return StandardCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.receipt, color: mainColor),
            title: Text(e['concept'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
              onPressed: () => deleteExpense(e['id']),
            ),
          ),
          if (hasImage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(Icons.image, color: mainColor),
                label: Text('Ver imagen', style: TextStyle(color: mainColor)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const Text("No se pudo cargar la imagen"),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gastos del almuerzo', style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 12),
        child: ElevatedButton.icon(
          onPressed: _navigateToAddExpense,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text("Añadir gasto", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? const Center(child: Text('No hay gastos'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          return buildExpenseTile(expenses[index], mainColor);
        },
      ),
    );
  }
}
