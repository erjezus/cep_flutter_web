import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/create_product_dialog.dart';
import 'package:cep_flutter_web/services/event_management_service.dart';

class EventProductsScreen extends StatefulWidget {
  final int eventId;
  final String? eventName;

  const EventProductsScreen({
    required this.eventId,
    this.eventName,
    super.key,
  });

  @override
  State<EventProductsScreen> createState() => _EventProductsScreenState();
}

class _EventProductsScreenState extends State<EventProductsScreen> {
  final baseUrl = AppConfig.baseUrl;

  Map<String, List<dynamic>> groupedProducts = {};
  Map<String, bool> expandedSections = {};
  bool _isLoading = true;
  bool _isRecalculating = false;
  String? _error;

  final _eventService = EventManagementService();

  @override
  void initState() {
    super.initState();
    fetchEventProducts();
  }

  Future<void> fetchEventProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/event-products?eventId=${widget.eventId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, List<dynamic>> grouped = {};
        final Map<String, bool> expandStates = {};

        for (var item in data) {
          final typology = (item['typology'] ?? 'Otros').toString();
          grouped.putIfAbsent(typology, () => []);
          grouped[typology]!.add(item);
          expandStates.putIfAbsent(typology, () => true);
        }

        setState(() {
          groupedProducts = grouped;
          expandedSections = expandStates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar productos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red: $e';
        _isLoading = false;
      });
    }
  }

  /// Abre el diálogo de creación de producto y recarga la lista si se crea.
  Future<void> _openCreateProductDialog() async {
    final created = await CreateProductDialog.show(context, widget.eventId);
    if (created) {
      await fetchEventProducts();
    }
  }

  Future<void> _recalculatePrices() async {
    setState(() => _isRecalculating = true);
    try {
      final rowsUpdated =
          await _eventService.recalculateConsumptionPrices(widget.eventId);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Precios recalculados correctamente. $rowsUpdated consumiciones actualizadas.',
      );
      await fetchEventProducts();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error al recalcular precios: $e');
    } finally {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  Future<void> _toggleVisibility(dynamic product, bool newValue) async {
    final int id = product['id'];

    // Optimistic update
    setState(() => product['visible'] = newValue);

    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/api/event-products/visibility?id=$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'visible': newValue}),
      );
      if (res.statusCode != 200) {
        setState(() => product['visible'] = !newValue);
        if (!mounted) return;
        AppSnackBar.error(context, 'Error al actualizar visibilidad');
      }
    } catch (e) {
      setState(() => product['visible'] = !newValue);
      if (!mounted) return;
      AppSnackBar.error(context, 'Error de red: $e');
    }
  }

  Future<void> saveCustomPrice(int productId, double customPrice) async {
    try {
      final body = jsonEncode({
        "event_id": widget.eventId,
        "product_id": productId,
        "custom_price": customPrice,
      });

      final res = await http.post(
        Uri.parse('$baseUrl/api/event-products'),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        AppSnackBar.success(context, "Precio actualizado");
        fetchEventProducts();
      } else {
        if (!mounted) return;
        AppSnackBar.error(context, "Error al guardar: ${res.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, "Error de red: $e");
    }
  }

  Future<void> resetCustomPrice(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/event-products?id=$id'),
      );

      if (res.statusCode == 204 || res.statusCode == 200) {
        if (!mounted) return;
        AppSnackBar.info(context, "Precio restablecido al valor base");
        fetchEventProducts();
      } else {
        if (!mounted) return;
        AppSnackBar.error(context, "Error al restablecer: ${res.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, "Error de red: $e");
    }
  }

  void showEditPriceDialog(dynamic product) {
    final double currentPrice =
        double.tryParse(product['custom_price'].toString()) ?? 0;
    final double basePrice =
        double.tryParse(product['unit_price'].toString()) ?? 0;
    final controller =
        TextEditingController(text: currentPrice.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            product['product_name']?.toString() ?? 'Producto',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Precio base: €${basePrice.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: "Precio para este evento (€)",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check),
            label: const Text("Guardar"),
            onPressed: () {
              final parsed =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null && parsed >= 0) {
                Navigator.pop(context);
                saveCustomPrice(product['product_id'], parsed);
              } else {
                AppSnackBar.error(context, "Introduce un precio válido");
              }
            },
          ),
        ],
      ),
    );
  }

  Widget buildProductTile(dynamic p, Color mainColor) {
    final double customPrice =
        double.tryParse(p['custom_price'].toString()) ?? 0;
    final double basePrice =
        double.tryParse(p['unit_price'].toString()) ?? 0;
    final bool hasCustom = (p['id'] ?? 0) != 0 && customPrice != basePrice;
    final bool visible = p['visible'] == true || p['visible'] == 1;

    return Opacity(
      opacity: visible ? 1.0 : 0.45,
      child: StandardCard(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: mainColor.withOpacity(0.1),
                child: Icon(Icons.local_drink, color: mainColor),
              ),
              title: Text(
                p['product_name']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Precio base: €${basePrice.toStringAsFixed(2)}",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          "Precio evento: €${customPrice.toStringAsFixed(2)}",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasCustom ? mainColor : Colors.black87,
                          ),
                        ),
                      ),
                      if (hasCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text("personalizado",
                              style:
                                  TextStyle(fontSize: 10, color: mainColor)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCustom)
                    IconButton(
                      tooltip: "Restablecer precio base",
                      icon:
                          const Icon(Icons.restart_alt, color: Colors.grey),
                      onPressed: () => resetCustomPrice(p['id']),
                    ),
                  IconButton(
                    tooltip: "Editar precio",
                    icon: Icon(Icons.edit, color: mainColor),
                    onPressed: () => showEditPriceDialog(p),
                  ),
                ],
              ),
            ),
            // ── Toggle de visibilidad ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 6),
              child: Row(
                children: [
                  Icon(
                    visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Visible en consumo',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.8,
                    alignment: Alignment.centerRight,
                    child: Switch(
                      value: visible,
                      onChanged: (v) => _toggleVisibility(p, v),
                      activeColor: mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccordion(String typology, List products, bool expanded,
      ValueChanged<bool> onToggle, Color mainColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: StandardSection(
        title: typology,
        icon: Icons.sell,
        color: mainColor,
        initiallyExpanded: expanded,
        onToggle: () => onToggle(!expanded),
        children:
            products.map<Widget>((p) => buildProductTile(p, mainColor)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.eventName != null
              ? "Precios · ${widget.eventName}"
              : "Precios",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isRecalculating
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white54,
                    ),
                    onPressed: _isLoading ? null : _recalculatePrices,
                    icon: const Icon(Icons.calculate_outlined, size: 20),
                    label: const Text("Recalcular precios"),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProductDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          "Crear producto",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _isLoading
          ? const SkeletonList(itemCount: 5)
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : groupedProducts.isEmpty
                  ? EmptyState(
                      icon: Icons.sell,
                      title: "No hay productos disponibles",
                      message: "Aquí podrás ajustar el precio de cada producto para el evento.",
                      actionLabel: "Crear producto",
                      actionIcon: Icons.add,
                      onAction: _openCreateProductDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: fetchEventProducts,
                      child: ResponsiveContainer(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: groupedProducts.entries.map((entry) {
                            final typology = entry.key;
                            final products = entry.value;
                            final expanded =
                                expandedSections[typology] ?? false;

                            return buildAccordion(
                              typology,
                              products,
                              expanded,
                              (value) => setState(
                                  () => expandedSections[typology] = value),
                              mainColor,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
    );
  }
}

