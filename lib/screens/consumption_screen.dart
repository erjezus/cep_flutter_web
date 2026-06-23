import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/standard_section.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/app_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ConsumptionScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int eventId;

  const ConsumptionScreen({
    required this.userId,
    required this.userName,
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
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/consumptions?userId=${widget.userId}&eventId=${widget.eventId}'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          // Ordenar días de más reciente a más antiguo
          final sorted = List.from(data)
            ..sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
          setState(() {
            consumptionsByDay = sorted;
            computeSummary(sorted);
          });
      } else {
        _showError("Error al cargar consumiciones");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Error de red al cargar consumiciones");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    AppSnackBar.error(context, message);
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: "¿Eliminar consumición?",
      message: "Esta acción no se puede deshacer.",
      confirmLabel: "Eliminar",
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (confirmed) _deleteConsumption(id);
  }

  void _deleteConsumption(int id) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/consumptions/$id'));
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccess("Consumición eliminada");
        fetchConsumptions();
      } else {
        throw Exception("Error al eliminar");
      }
    } catch (e) {
      if (!mounted) return;
      _showError("Error al eliminar consumición");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSuccess(String message) {
    AppSnackBar.success(context, message);
  }

  // ... [imports y clase intactos hasta _generatePdf]

  void _generatePdf(String userName) async {
    try {
      final pdf = pw.Document();
      final fontData = await rootBundle.load('assets/fonts/Roboto.ttf');
      final ttf = pw.Font.ttf(fontData);
      final logoBytes = await rootBundle.load('assets/logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf),
          header: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, height: 40),
                pw.Text(userName,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.Text("Resumen total", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Producto', 'Cantidad', 'Unitario', 'Total'],
              data: totalSummary.entries.map<List<String>>((e) {
                final name = e.key.toString();
                final quantity = e.value['quantity'].toString();
                final unit = (e.value['unit_price'] as num).toStringAsFixed(2);
                final total = (e.value['total'] as num).toStringAsFixed(2);
                return [name, quantity, '€$unit', '€$total'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL GENERAL: €${grandTotal.toStringAsFixed(2)}",
                style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Detalle por día",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            ...consumptionsByDay.map((day) {
              final date = day['date'];
              final formatted = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
              final consumptions = day['consumptions'];

              final rows = consumptions.map<List<String>>((c) {
                final name = c['product_name']?.toString() ?? 'Producto';
                final qty = c['quantity'].toString();
                final time = c['consumed_at'] != null
                    ? DateFormat('HH:mm').format(DateTime.parse(c['consumed_at']).add(const Duration(hours: 2)))
                    : 'Hora desconocida';
                final price = (c['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00';
                return [name, qty, time, '€$price'];
              }).toList();

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(formatted, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Table.fromTextArray(
                    headers: ['Producto', 'Cantidad', 'Hora', 'Total'],
                    data: rows,
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
                  pw.SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);

    } catch (e) {
      _showError("Error generando PDF: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    final Color mainColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis consumiciones"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: "Descargar PDF",
            onPressed: () => _generatePdf(this.widget.userName),
          )
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: isLoading
              ? const SkeletonList(itemCount: 5)
              : consumptionsByDay.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long,
                      title: "No hay consumiciones registradas",
                      message: "Cuando consumas algo aparecerá aquí, agrupado por día.",
                    )
                  : RefreshIndicator(
                      onRefresh: () async => fetchConsumptions(),
                      child: ListView(
                      children: [
                        ...consumptionsByDay.map((dayData) {
                          final rawDate = dayData['date'];
                          final formattedDate =
                              DateFormat('dd-MM-yyyy').format(DateTime.parse(rawDate));
                          final List consumptions = dayData['consumptions'];
                          final isExpanded = expandedDates.contains(rawDate);
                          return buildAccordion(
                              formattedDate, rawDate, consumptions, isExpanded, mainColor);
                        }).toList(),
                        const SizedBox(height: 12),
                        buildSummary(mainColor),
                        const SizedBox(height: 80),
                      ],
                    ),
                    ),
        ),
      ),
      bottomNavigationBar: (isLoading || consumptionsByDay.isEmpty)
          ? null
          : _buildStickyTotal(mainColor),
    );
  }

  /// Barra inferior fija que muestra siempre el total general, sin tener
  /// que hacer scroll hasta el final de la lista.
  Widget _buildStickyTotal(Color mainColor) {
    return Material(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: mainColor, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      "Total general",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  "€${grandTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData getIconForProduct(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("cerveza") || lower.contains("botell")) return Icons.local_drink;
    if (lower.contains("comida") || lower.contains("comensal")) return Icons.restaurant;
    return Icons.fastfood;
  }

  Widget buildAccordion(
      String title, String dateKey, List items, bool isExpanded, Color mainColor) {
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
        children: (List.from(items)..sort((a, b) {
              final da = DateTime.tryParse(a['consumed_at'] ?? '') ?? DateTime(2000);
              final db = DateTime.tryParse(b['consumed_at'] ?? '') ?? DateTime(2000);
              return db.compareTo(da); // descendente: más reciente primero
            })).map<Widget>((c) {
          final productName = c['product_name']?.toString() ?? 'Producto';
          final consumedAtRaw = c['consumed_at'];
          final consumedAtFormatted = consumedAtRaw != null
              ? DateFormat('HH:mm').format(
              (DateTime.tryParse(consumedAtRaw) ?? DateTime(2000))
                  .add(const Duration(hours: 2)))
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
          ..insert(
              0,
              Padding(
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
            child:
            Text("Resumen total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...totalSummary.entries.map((entry) {
            final name = entry.key;
            final details = entry.value;
            return ListTile(
              title: Text(name),
              subtitle:
              Text("Cantidad: ${details['quantity']} • Unitario: €${details['unit_price']}"),
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
}