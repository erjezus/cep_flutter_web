import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cep_flutter_web/config/config.dart';

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

    print("UserId: ${widget.userId}");
    print("EventId: ${widget.eventId}");

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar consumiciones"),
            backgroundColor: Colors.grey[800],
          ),
        );
      }
    } catch (e) {
      // Error handling
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

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("¿Eliminar consumición?"),
        content: Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteConsumption(id);
    }
  }

  void _deleteConsumption(int id) async {
    setState(() => isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/consumptions/$id'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Consumición eliminada"),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        fetchConsumptions();
      } else {
        throw Exception("Error al eliminar");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al eliminar consumición"),
          backgroundColor: Colors.grey[800],
        ),
      );
      setState(() => isLoading = false);
    }
  }

  IconData getIconForProduct(String name) {
    if (name.toLowerCase().contains("cerveza") || name.toLowerCase().contains("botell")) return Icons.local_drink;
    if (name.toLowerCase().contains("comida") || name.toLowerCase().contains("comensal")) return Icons.restaurant;
    return Icons.fastfood;
  }

  Widget buildAccordion(String title, String dateKey, List items, bool isExpanded, Color mainColor, Color bgColor) {
    double dayTotal = 0.0;
    for (var c in items) {
      dayTotal += c['total_price'] ?? 0.0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: bgColor,
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                expandedDates.add(dateKey);
              } else {
                expandedDates.remove(dateKey);
              }
            });
          },
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
              Text("Total: €${dayTotal.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          children: items.map<Widget>((c) {
            final productName = c['product_name']?.toString() ?? 'Producto';
            final consumedAtRaw = c['consumed_at'];
            final consumedAtFormatted = consumedAtRaw != null
                ? DateFormat('HH:mm').format(DateTime.tryParse(consumedAtRaw) ?? DateTime(2000))
                : 'Hora desconocida';

            return ListTile(
              leading: Icon(getIconForProduct(productName), color: mainColor),
              title: Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Cantidad: ${c['quantity']} • $consumedAtFormatted"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("€${(c['total_price'] ?? 0.0).toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.grey[700]),
                    onPressed: () => _confirmDelete(c['id']),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildSummary(Color mainColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text("Resumen total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainColor)),
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
        Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total: €${grandTotal.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Color(0xFFD32F2F);
    final List<Color> dayColors = [Colors.white, Colors.grey[100]!, Colors.grey[200]!];

    return Scaffold(
      backgroundColor: Colors.white, // 👈 evita bandas negras
      appBar: AppBar(
        title: Text("Mis consumiciones"),
        backgroundColor: mainColor,
      ),
      body: SafeArea( // 👈 respeta notch y safe areas
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : consumptionsByDay.isEmpty
            ? Center(child: Text("No hay consumiciones registradas"))
            : ListView(
          children: [
            ...consumptionsByDay.asMap().entries.map((entry) {
              final index = entry.key;
              final dayData = entry.value;
              final rawDate = dayData['date'];
              final formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate));
              final List consumptions = dayData['consumptions'];
              final isExpanded = expandedDates.contains(rawDate);
              final bgColor = dayColors[index % dayColors.length];
              return buildAccordion(formattedDate, rawDate, consumptions, isExpanded, mainColor, bgColor);
            }).toList(),
            const SizedBox(height: 12),
            buildSummary(mainColor),
          ],
        ),
      ),
    );
  }
}
