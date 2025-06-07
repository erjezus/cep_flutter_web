import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';

class ProductScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const ProductScreen({required this.userId, required this.eventId, super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, List> groupedProducts = {};
  Map<String, bool> expandedSections = {};
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchGroupedProducts();
  }

  void fetchGroupedProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/api/products/grouped'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final Map<String, List<dynamic>> grouped = {};
      final Map<String, bool> expandStates = {};

      for (var item in data) {
        final typology = item['typology'];
        final List<dynamic> products = item['products'];
        grouped[typology] = products;
        expandStates[typology] = false;
      }

      setState(() {
        groupedProducts = grouped;
        expandedSections = expandStates;
      });
    }
  }

  void registerConsumption(int productId, int quantity) async {
    try {
      final body = jsonEncode({
        "user_id": widget.userId,
        "product_id": productId,
        "event_id": widget.eventId,
        "quantity": quantity,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/api/consumptions'),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Consumición registrada"),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de red: $e")),
      );
    }
  }

  void showQuantityDialog(int productId, String productName) {
    int quantity = 1;
    final controller = TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            "Añadir $productName",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Selecciona la cantidad", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (quantity > 1) {
                      quantity--;
                      controller.text = quantity.toString();
                    }
                  },
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        quantity = parsed;
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    quantity++;
                    controller.text = quantity.toString();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check),
            label: const Text("Confirmar"),
            onPressed: () {
              registerConsumption(productId, quantity);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget buildProductTile(dynamic p, Color mainColor) {
    return StandardCard(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: ListTile(
        leading: p['image_url'] != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            p['image_url'],
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.local_drink, color: mainColor),
          ),
        )
            : Icon(Icons.local_drink, color: mainColor),
        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Precio base: €${p['unit_price']}"),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: mainColor, size: 32),
          onPressed: () => showQuantityDialog(p['id'], p['name']),
        ),
      ),
    );
  }

  Widget buildAccordion(String typology, List products, bool expanded, ValueChanged<bool> onToggle, Color mainColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StandardSection(
        title: typology,
        icon: Icons.fastfood,
        color: mainColor,
        initiallyExpanded: expanded,
        onToggle: () => onToggle(!expanded),
        children: products.map<Widget>((p) => buildProductTile(p, mainColor)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Productos", style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: groupedProducts.isEmpty
          ? const Center(child: Text("No hay productos disponibles"))
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: groupedProducts.entries.map((entry) {
          final typology = entry.key;
          final products = entry.value;
          final expanded = expandedSections[typology] ?? false;

          return buildAccordion(
            typology,
            products,
            expanded,
                (value) => setState(() => expandedSections[typology] = value),
            mainColor,
          );
        }).toList(),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 12),
        child: ElevatedButton.icon(
          onPressed: () {
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
          icon: const Icon(Icons.receipt_long),
          label: const Text(
            "Mis consumiciones",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
    );
  }
}
