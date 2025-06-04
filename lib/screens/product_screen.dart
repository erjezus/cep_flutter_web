import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';

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

  void registerConsumption(int productId, double price) async {
    try {
      final body = jsonEncode({
        "user_id": widget.userId,
        "product_id": productId,
        "event_id": widget.eventId,
        "quantity": 1
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
          onPressed: () => registerConsumption(p['id'], p['unit_price']),
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
        title: const Text("Productos",style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: groupedProducts.isEmpty
          ? const Center(child: Text("No hay productos disponibles"))
          : ListView(
        padding: const EdgeInsets.all(16),
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
    );
  }
}