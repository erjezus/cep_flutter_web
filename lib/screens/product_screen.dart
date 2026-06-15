import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';

class ProductScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int eventId;

  const ProductScreen({required this.userId,required this.userName, required this.eventId, super.key});

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
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
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
        AppSnackBar.success(context, "Consumición registrada");
      }
    } catch (e) {
      AppSnackBar.error(context, "Error de red: $e");
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
              backgroundColor: AppColors.primary,
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
    final Color mainColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Productos"),
      ),
      body: ResponsiveContainer(
        child: groupedProducts.isEmpty
            ? const EmptyState(
                icon: Icons.fastfood,
                title: "No hay productos disponibles",
                message: "Cuando haya productos podrás registrar tus consumiciones.",
              )
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsumptionScreen(
                userId: widget.userId,
                userName: widget.userName,
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
