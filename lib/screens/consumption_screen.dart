import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';

class ConsumptionScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const ConsumptionScreen({
    required this.userId,
    required this.eventId,
    super.key,
  });

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  List consumptionsByDay = [];
  Set<String> expandedDates = {};
  bool isLoading = false;
  Map<String, dynamic> totalSummary = {};
  double grandTotal = 0.0;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchConsumptions();
  }

  void fetchConsumptions() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/consumptions?userId=${widget.userId}&eventId=${widget.eventId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          consumptionsByDay = data;
          computeSummary(data);
        });
      } else {
        _showError("Error al cargar consumiciones");
      }
    } catch (e) {
      _showError("Error de red al cargar consumiciones");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void computeSummary(List<dynamic> data) {
    totalSummary.clear();
    grandTotal = 0.0;

    for (var day in data) {
      for (var c in day['consumptions']) {
        final name = c['product_name']?.toString() ?? 'Producto';
        final unit = (c['unit_price'] ?? 0).toDouble();
        final quantity = (c['quantity'] ?? 0) as int;
        final total = (c['total_price'] ?? 0).toDouble();

        if (!totalSummary.containsKey(name)) {
          totalSummary[name] = {
            'quantity': 0,
            'unit_price': unit,
            'total': 0.0,
          };
        }

        totalSummary[name]['quantity'] += quantity;
        totalSummary[name]['total'] += total;
        grandTotal += total;
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.grey[800]),
    );
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar consumición?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) _deleteConsumption(id);
  }

  void _deleteConsumption(int id) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/consumptions/$id'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccess("Consumición eliminada");
        fetchConsumptions();
      } else {
        throw Exception("Error al eliminar");
      }
    } catch (e) {
      _showError("Error al eliminar consumición");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFD32F2F)),
    );
  }

  IconData getIconForProduct(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("cerveza") || lower.contains("botell")) return Icons.local_drink;
    if (lower.contains("comida") || lower.contains("comensal")) return Icons.restaurant;
    return Icons.fastfood;
  }

  Widget buildAccordion(String title, String dateKey, List items, bool isExpanded, Color mainColor) {
    double dayTotal = 0.0;
    for (var c in items) {
      dayTotal += c['total_price'] ?? 0.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StandardSection(
        title: title,
        icon: Icons.calendar_today,
        color: mainColor,
        initiallyExpanded: isExpanded,
        onToggle: () {
          setState(() {
            if (isExpanded) {
              expandedDates.remove(dateKey);
            } else {
              expandedDates.add(dateKey);
            }
          });
        },
        children: items.map<Widget>((c) {
          final productName = c['product_name']?.toString() ?? 'Producto';
          final consumedAtRaw = c['consumed_at'];
          final consumedAtFormatted = consumedAtRaw != null
              ? DateFormat('HH:mm').format(
              (DateTime.tryParse(consumedAtRaw) ?? DateTime(2000)).add(const Duration(hours: 2)))
              : 'Hora desconocida';

          return ListTile(
            leading: Icon(getIconForProduct(productName), color: mainColor),
            title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Cantidad: ${c['quantity']} • $consumedAtFormatted"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("€${(c['total_price'] ?? 0.0).toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.grey[700]),
                  onPressed: () => _confirmDelete(c['id']),
                ),
              ],
            ),
          );
        }).toList()
          ..insert(0, Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text("Total: €${dayTotal.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
      ),
    );
  }

  Widget buildSummary(Color mainColor) {
    return StandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Resumen total",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...totalSummary.entries.map((entry) {
            final name = entry.key;
            final details = entry.value;
            return ListTile(
              title: Text(name),
              subtitle: Text("Cantidad: ${details['quantity']} • Unitario: €${details['unit_price']}"),
              trailing: Text("€${details['total'].toStringAsFixed(2)}"),
            );
          }).toList(),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total: €${grandTotal.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Mis consumiciones", style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : consumptionsByDay.isEmpty
            ? const Center(child: Text("No hay consumiciones registradas"))
            : ListView(
          children: [
            ...consumptionsByDay.map((dayData) {
              final rawDate = dayData['date'];
              final formattedDate =
              DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate));
              final List consumptions = dayData['consumptions'];
              final isExpanded = expandedDates.contains(rawDate);
              return buildAccordion(formattedDate, rawDate, consumptions, isExpanded, mainColor);
            }).toList(),
            const SizedBox(height: 12),
            buildSummary(mainColor),
          ],
        ),
      ),
    );
  }
}