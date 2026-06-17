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
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/api/lunches/expenses?lunchId=${widget.lunchId}');
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          expenses = data is List ? data : [];
        });
      } else {
        AppSnackBar.error(context, 'Error al cargar gastos');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error de red o de formato');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteExpense(int id) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿Eliminar gasto?',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;

    final unlinkUrl = Uri.parse('$baseUrl/api/expense_lunch?expense_id=$id&lunch_id=${widget.lunchId}');
    final unlinkRes = await http.delete(unlinkUrl);

    if (unlinkRes.statusCode != 204) {
      AppSnackBar.error(context, "Error al desasociar gasto del almuerzo");
      return;
    }

    final response = await http.delete(Uri.parse('$baseUrl/api/expenses/$id'));

    if (response.statusCode == 200) {
      setState(() {
        expenses.removeWhere((e) => e['id'] == id);
      });
      AppSnackBar.success(context, "Gasto eliminado");
    } else {
      AppSnackBar.error(context, "Error al eliminar el gasto");
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
    final mainColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gastos del almuerzo'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        icon: const Icon(Icons.add),
        label: const Text("Añadir gasto", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ResponsiveContainer(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : expenses.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long,
                    title: 'No hay gastos',
                    message: 'Añade los gastos de este almuerzo para repartir el coste.',
                    actionLabel: 'Añadir gasto',
                    actionIcon: Icons.add_circle_outline,
                    onAction: _navigateToAddExpense,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return buildExpenseTile(expenses[index], mainColor);
                    },
                  ),
      ),
    );
  }
}
