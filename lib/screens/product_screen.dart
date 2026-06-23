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
  final Set<int> _pendingProducts = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final baseUrl = AppConfig.baseUrl;

  // ── Caché estático por eventId (se comparte entre instancias) ────────────
  static final Map<int, Map<String, List>> _cache = {};
  static final Map<int, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 10);

  // ── Helpers de sesión ────────────────────────────────────────────────────
  List<dynamic> get _allProducts =>
      groupedProducts.values.expand((l) => l).toList();

  int get _totalSessionItems =>
      _sessionCounts.values.fold(0, (s, c) => s + c);

  double get _totalSessionCost {
    double total = 0;
    for (final entry in _sessionCounts.entries) {
      if (entry.value == 0) continue;
      final p = _allProducts.firstWhere(
        (p) => p['id'] == entry.key,
        orElse: () => null,
      );
      if (p != null) {
        total += (double.tryParse('${p['unit_price']}') ?? 0) * entry.value;
      }
    }
    return total;
  }

  bool get _hasSession => _totalSessionItems > 0;

  @override
  void initState() {
    super.initState();
    _fetchGroupedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupedProducts({bool forceRefresh = false}) async {
    final id = widget.eventId;
    final cached = _cache[id];
    final age = _cacheTime[id];
    final isFresh =
        age != null && DateTime.now().difference(age) < _cacheDuration;

    if (!forceRefresh && cached != null && isFresh) {
      if (!mounted) return;
      setState(() {
        groupedProducts = cached;
        _isLoading = false;
      });
      return;
    }

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
        _cache[id] = grouped;
        _cacheTime[id] = DateTime.now();
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

  // ── Confirmación al salir si hay sesión ──────────────────────────────────
  Future<bool> _confirmExit() async {
    if (!_hasSession) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('¿Salir de Consumir?'),
        content: Text(
          'Llevas $_totalSessionItems consumición${_totalSessionItems == 1 ? '' : 'es'} '
          'esta sesión (€${_totalSessionCost.toStringAsFixed(2)}).\n\n'
          'Están guardadas en el servidor, no se perderán.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quedarme')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salir')),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _quickAdd(int productId, String productName) async {
    HapticFeedback.lightImpact();
    setState(() {
      _sessionCounts[productId] = (_sessionCounts[productId] ?? 0) + 1;
      _pendingProducts.add(productId);
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
    } finally {
      if (mounted) setState(() => _pendingProducts.remove(productId));
    }
  }

  void _showQuantityDialog(int productId, String productName) {
    int quantity = 1;
    final controller = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(productName,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
      _pendingProducts.add(productId);
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
    } finally {
      if (mounted) setState(() => _pendingProducts.remove(productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _confirmExit();
        if (canLeave && mounted) Navigator.pop(context);
      },
      child: Scaffold(
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
                      // ── Barra de hint + búsqueda ────────────────────────
                      Container(
                        color: AppColors.primary.withOpacity(0.06),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.touch_app,
                                    size: 13, color: Colors.grey[500]),
                                const SizedBox(width: 5),
                                Text(
                                  'Toca para añadir 1 · mantén para más',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim().toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Buscar producto…',
                                hintStyle:
                                    TextStyle(fontSize: 14, color: Colors.grey[400]),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFEEEEEE)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Resumen de sesión ───────────────────────────────
                      if (_hasSession)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          color: AppColors.primary.withOpacity(0.09),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          child: Row(
                            children: [
                              Icon(Icons.shopping_basket_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Esta sesión: $_totalSessionItems consumición${_totalSessionItems == 1 ? '' : 'es'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '€${_totalSessionCost.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // ── Lista de productos ──────────────────────────────
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              _fetchGroupedProducts(forceRefresh: true),
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
                                      return _priority(a.key)
                                          .compareTo(_priority(b.key));
                                    }))
                                  .map((entry) => _buildCategory(
                                      entry.key, entry.value))
                                  .where((w) => w != null)
                                  .cast<Widget>()
                                  .toList(),
                            ),
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
            if (mounted) setState(() => _sessionCounts.clear());
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Mis consumiciones',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget? _buildCategory(String typology, List products) {
    // Filtrar por búsqueda
    final filtered = _searchQuery.isEmpty
        ? products
        : products
            .where((p) =>
                (p['name'] as String)
                    .toLowerCase()
                    .contains(_searchQuery))
            .toList();

    if (filtered.isEmpty) return null;

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
              for (int i = 0; i < filtered.length; i++) ...[
                _ProductRow(
                  product: filtered[i],
                  sessionCount: _sessionCounts[filtered[i]['id']] ?? 0,
                  isPending: _pendingProducts.contains(filtered[i]['id']),
                  onTap: () =>
                      _quickAdd(filtered[i]['id'], filtered[i]['name']),
                  onLongPress: () => _showQuantityDialog(
                      filtered[i]['id'], filtered[i]['name']),
                ),
                if (i < filtered.length - 1)
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
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProductRow({
    required this.product,
    required this.sessionCount,
    required this.isPending,
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
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Badge / spinner / icono añadir
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: widget.isPending
                      ? SizedBox(
                          key: const ValueKey('spinner'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                      : hasCount
                          ? Container(
                              key: ValueKey('badge_$count'),
                              constraints:
                                  const BoxConstraints(minWidth: 32),
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
