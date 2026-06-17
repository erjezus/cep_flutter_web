import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';

class ProductScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final int eventId;

  const ProductScreen({
    required this.userId,
    required this.userName,
    required this.eventId,
    super.key,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Map<String, List> groupedProducts = {};
  final Map<int, int> _sessionCounts = {};
  bool _isLoading = true;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchGroupedProducts();
  }

  Future<void> _fetchGroupedProducts() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/products/grouped'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, List<dynamic>> grouped = {};
        for (var item in data) {
          grouped[item['typology']] = item['products'];
        }
        setState(() {
          groupedProducts = grouped;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _quickAdd(int productId, String productName) async {
    HapticFeedback.lightImpact();
    setState(() {
      _sessionCounts[productId] = (_sessionCounts[productId] ?? 0) + 1;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/consumptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'product_id': productId,
          'event_id': widget.eventId,
          'quantity': 1,
        }),
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _sessionCounts[productId] =
              ((_sessionCounts[productId] ?? 1) - 1).clamp(0, 999);
        });
        AppSnackBar.error(context, 'Error al registrar $productName');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sessionCounts[productId] =
            ((_sessionCounts[productId] ?? 1) - 1).clamp(0, 999);
      });
      AppSnackBar.error(context, 'Error de red');
    }
  }

  void _showQuantityDialog(int productId, String productName) {
    int quantity = 1;
    final controller = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(productName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cuántas unidades?',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0) quantity = parsed;
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 17),
            label: const Text('Añadir'),
            onPressed: () {
              Navigator.pop(context);
              _registerMultiple(productId, productName, quantity);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _registerMultiple(
      int productId, String productName, int quantity) async {
    setState(() {
      _sessionCounts[productId] =
          (_sessionCounts[productId] ?? 0) + quantity;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/consumptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'product_id': productId,
          'event_id': widget.eventId,
          'quantity': quantity,
        }),
      );
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() {
          _sessionCounts[productId] =
              ((_sessionCounts[productId] ?? quantity) - quantity)
                  .clamp(0, 999);
        });
        AppSnackBar.error(context, 'Error al registrar');
      } else {
        AppSnackBar.success(context, '$quantity × $productName registrado');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error de red');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumir')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedProducts.isEmpty
              ? const EmptyState(
                  icon: Icons.fastfood,
                  title: 'No hay productos disponibles',
                  message:
                      'Cuando haya productos podrás registrar tus consumiciones.',
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.primary.withOpacity(0.06),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      child: Row(
                        children: [
                          Icon(Icons.touch_app,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            'Toca para añadir 1 · mantén pulsado para más cantidad',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ResponsiveContainer(
                        child: ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          children: (groupedProducts.entries.toList()
                            ..sort((a, b) {
                              int _priority(String key) {
                                final k = key.toLowerCase();
                                if (k.contains('bebida')) return 0;
                                if (k.contains('comida')) return 1;
                                return 2;
                              }
                              return _priority(a.key).compareTo(_priority(b.key));
                            })).map((entry) {
                            return _buildCategory(entry.key, entry.value);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsumptionScreen(
                userId: widget.userId,
                userName: widget.userName,
                eventId: widget.eventId,
              ),
            ),
          );
          if (mounted) {
            setState(() => _sessionCounts.clear());
          }
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Mis consumiciones',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCategory(String typology, List products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            typology.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < products.length; i++) ...[
                _ProductRow(
                  product: products[i],
                  sessionCount: _sessionCounts[products[i]['id']] ?? 0,
                  onTap: () => _quickAdd(products[i]['id'], products[i]['name']),
                  onLongPress: () => _showQuantityDialog(
                      products[i]['id'], products[i]['name']),
                ),
                if (i < products.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 0),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Fila de producto ──────────────────────────────────────────────────────
class _ProductRow extends StatefulWidget {
  final dynamic product;
  final int sessionCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProductRow({
    required this.product,
    required this.sessionCount,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Color?> _bgAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _bgAnim = ColorTween(
      begin: Colors.white,
      end: AppColors.primary.withOpacity(0.07),
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final count = widget.sessionCount;
    final hasCount = count > 0;

    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, child) => Material(
        color: _bgAnim.value,
        child: InkWell(
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // Nombre y precio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: hasCount
                              ? AppColors.primary
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '€${p['unit_price']}',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge o icono de añadir
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: hasCount
                      ? Container(
                          key: ValueKey('badge_$count'),
                          constraints: const BoxConstraints(minWidth: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : Icon(
                          key: const ValueKey('add_icon'),
                          Icons.add_circle_outline,
                          color: Colors.grey[400],
                          size: 22,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
