import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';

class EventOverviewScreen extends StatefulWidget {
  final int eventId;
  final String? eventName;
  final String userRole;

  const EventOverviewScreen({
    required this.eventId,
    this.eventName,
    this.userRole = 'USER',
    super.key,
  });

  @override
  State<EventOverviewScreen> createState() => _EventOverviewScreenState();
}

class _EventOverviewScreenState extends State<EventOverviewScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOverview();
  }

  Future<void> _fetchOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/summary/event-overview?eventId=${widget.eventId}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _data = Map<String, dynamic>.from(
              jsonDecode(utf8.decode(res.bodyBytes)));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar el resumen (${res.statusCode})';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.eventName != null
            ? 'Resumen · ${widget.eventName}'
            : 'Resumen del evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: _fetchOverview,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOverview,
                    child: ResponsiveContainer(
                      maxWidth: 700,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          if (widget.userRole.toUpperCase() == 'ADMIN')
                            _TotalsCard(data: _data!),
                          _DrinkCard(data: _data!),
                          _FoodCard(data: _data!, eventId: widget.eventId),
                          _CommonExpensesCard(data: _data!, eventId: widget.eventId),
                          _LunchCard(data: _data!),
                          _DepositsCard(data: _data!, eventId: widget.eventId),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers compartidos
// ---------------------------------------------------------------------------

String _fmt(dynamic v) => '€${(v as num? ?? 0).toDouble().toStringAsFixed(2)}';

Color _lossColor(dynamic v) {
  final val = (v as num? ?? 0).toDouble();
  if (val > 0) return AppColors.negative;
  if (val < 0) return AppColors.positive;
  return Colors.black54;
}

Color _neutralColor(dynamic v) {
  final val = (v as num? ?? 0).toDouble();
  if (val == 0) return Colors.black54;
  return Colors.black87;
}

/// Decoración compartida por todas las tarjetas de sección.
BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

/// Icono leading compartido por todas las tarjetas de sección.
Widget _leadingIcon(IconData icon, Color color) => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );

Widget _dataRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 📊 Tarjeta de totales generales (destacada)
// ---------------------------------------------------------------------------
class _TotalsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TotalsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalLoss = (data['total_loss'] as num? ?? 0).toDouble();
    final lossColor = totalLoss > 0 ? AppColors.negative : AppColors.positive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabecera coloreada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Totales del evento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data['user_count'] ?? 0} socios',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                _dataRow('Total gastado en el evento',
                    _fmt(data['total_expenses']),
                    valueColor: Colors.black87),
                _dataRow('Total consumido registrado',
                    _fmt(data['total_consumed']),
                    valueColor: _neutralColor(data['total_consumed'])),
                const Divider(height: 20),
                // Pérdida total destacada
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pérdida total',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: lossColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: lossColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        _fmt(data['total_loss']),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: lossColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _dataRow('Pérdida por socio', _fmt(data['loss_per_user']),
                    valueColor: _lossColor(data['loss_per_user'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🍺 Sección bebida (expandible)
// ---------------------------------------------------------------------------
class _DrinkCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _DrinkCard({required this.data});

  @override
  State<_DrinkCard> createState() => _DrinkCardState();
}

class _DrinkCardState extends State<_DrinkCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: _leadingIcon(Icons.local_bar, color),
          title: Text('Bebida',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color)),
          subtitle: Text(
            _fmt(widget.data['drink_expenses']),
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 4),
            _dataRow('Gastado en bebida',
                _fmt(widget.data['drink_expenses'])),
            _dataRow('Consumido registrado',
                _fmt(widget.data['drink_consumed'])),
            _dataRow('Pérdida bebida', _fmt(widget.data['drink_loss']),
                valueColor: _lossColor(widget.data['drink_loss'])),
            _dataRow('Pérdida por socio',
                _fmt(widget.data['drink_loss_per_user']),
                valueColor:
                    _lossColor(widget.data['drink_loss_per_user'])),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🍽️ Sección comida (expandible con desglose de gastos y consumiciones)
// ---------------------------------------------------------------------------
class _FoodCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int eventId;
  const _FoodCard({required this.data, required this.eventId});

  @override
  State<_FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<_FoodCard> {
  bool _expanded = false;
  bool _loading = false;
  bool _loaded = false;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _consumptions = [];

  Future<void> _load() async {
    if (_loaded) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse(
            '${AppConfig.baseUrl}/api/expenses?eventId=${widget.eventId}')),
        http.get(Uri.parse(
            '${AppConfig.baseUrl}/api/summary/all-users?eventId=${widget.eventId}')),
      ]);

      // Gastos de comida
      List<Map<String, dynamic>> expenses = [];
      if (results[0].statusCode == 200) {
        final all = List<dynamic>.from(
            jsonDecode(utf8.decode(results[0].bodyBytes)));
        expenses = all
            .where((e) => e['expense_type'] == 'Comida')
            .map<Map<String, dynamic>>((e) => {
                  'concept': e['concept'] ?? '',
                  'user_name': e['user_name'] ?? '?',
                  'amount': ((e['amount'] ?? 0.0) as num).toDouble(),
                })
            .toList()
          ..sort((a, b) =>
              (b['amount'] as double).compareTo(a['amount'] as double));
      }

      // Consumiciones de comida agregadas por producto
      List<Map<String, dynamic>> consumptions = [];
      if (results[1].statusCode == 200) {
        final users = List<dynamic>.from(
            jsonDecode(utf8.decode(results[1].bodyBytes)));
        final Map<String, Map<String, dynamic>> byProduct = {};
        for (final user in users) {
          for (final c
              in List<dynamic>.from(user['consumptions'] ?? [])) {
            if ((c['typology'] ?? '') != 'Comida') continue;
            final name =
                (c['product_name'] as String?)?.trim() ?? 'Desconocido';
            byProduct.putIfAbsent(
                name, () => {'name': name, 'qty': 0, 'total': 0.0});
            byProduct[name]!['qty'] = (byProduct[name]!['qty'] as int) +
                ((c['total_qty'] as num? ?? 0).toInt());
            byProduct[name]!['total'] =
                (byProduct[name]!['total'] as double) +
                    ((c['total_price'] as num? ?? 0).toDouble());
          }
        }
        consumptions = byProduct.values.toList()
          ..sort((a, b) =>
              (b['qty'] as int).compareTo(a['qty'] as int));
      }

      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _consumptions = consumptions;
        _loaded = true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _tableHeader(List<Widget> cells) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: cells),
      );

  Widget _headerCell(String text, {TextAlign align = TextAlign.left, double? width}) {
    final style = TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]);
    final t = Text(text, textAlign: align, style: style);
    return width != null ? SizedBox(width: width, child: t) : Expanded(child: t);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.food;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) {
            setState(() => _expanded = v);
            if (v) _load();
          },
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: _leadingIcon(Icons.restaurant, color),
          title: Text('Comida',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          subtitle: Text(
            _fmt(widget.data['food_expenses']),
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: color),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 4),
            _dataRow('Gastado en comida',
                _fmt(widget.data['food_expenses'])),
            _dataRow('Consumido registrado',
                _fmt(widget.data['food_consumed'])),
            _dataRow('Pérdida comida', _fmt(widget.data['food_loss']),
                valueColor: _lossColor(widget.data['food_loss'])),
            _dataRow('Pérdida por socio',
                _fmt(widget.data['food_loss_per_user']),
                valueColor:
                    _lossColor(widget.data['food_loss_per_user'])),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loaded) ...[
              // ── Gastos registrados ──────────────────────────────
              Row(children: [
                Icon(Icons.receipt_long, size: 14, color: color),
                const SizedBox(width: 6),
                Text('Gastos registrados',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ]),
              const SizedBox(height: 8),
              if (_expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Sin gastos de comida registrados.',
                      style:
                          TextStyle(color: Colors.black54, fontSize: 12)),
                )
              else ...[
                _tableHeader([
                  _headerCell('Concepto'),
                  _headerCell('Importe',
                      width: 64, align: TextAlign.right),
                ]),
                const Divider(height: 1),
                ..._expenses.map<Widget>((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['concept'] as String,
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.person_outline,
                                        size: 11,
                                        color: Colors.grey[500]),
                                    const SizedBox(width: 3),
                                    Text(
                                      e['user_name'] as String,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text(
                              _fmt(e['amount']),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ── Consumiciones por producto ───────────────────────
              Row(children: [
                Icon(Icons.bar_chart, size: 14, color: color),
                const SizedBox(width: 6),
                Text('Consumiciones por producto',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ]),
              const SizedBox(height: 8),
              if (_consumptions.isEmpty)
                const Text('Sin consumiciones de comida registradas.',
                    style:
                        TextStyle(color: Colors.black54, fontSize: 12))
              else ...[
                _tableHeader([
                  _headerCell('Producto'),
                  _headerCell('Uds.',
                      width: 40, align: TextAlign.center),
                  _headerCell('Total',
                      width: 64, align: TextAlign.right),
                ]),
                const Divider(height: 1),
                ..._consumptions.map<Widget>((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p['name'] as String,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('${p['qty']}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text(_fmt(p['total']),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 👥 Sección gastos comunes (expandible con usuario)
// ---------------------------------------------------------------------------
class _CommonExpensesCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int eventId;
  const _CommonExpensesCard({required this.data, required this.eventId});

  @override
  State<_CommonExpensesCard> createState() => _CommonExpensesCardState();
}

class _CommonExpensesCardState extends State<_CommonExpensesCard> {
  bool _expanded = false;
  bool _loading = false;
  bool _loaded = false;
  List<Map<String, dynamic>> _items = [];

  Future<void> _load() async {
    if (_loaded) return;
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          '${AppConfig.baseUrl}/api/expenses?eventId=${widget.eventId}'));
      if (res.statusCode == 200) {
        final all =
            List<dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)));
        final filtered = all
            .where((e) => e['expense_type'] == 'Común')
            .map<Map<String, dynamic>>((e) => {
                  'concept': e['concept'] ?? '',
                  'user_name': e['user_name'] ?? '?',
                  'amount': ((e['amount'] ?? 0.0) as num).toDouble(),
                  'user_share': ((e['user_share'] ??
                          widget.data['common_expenses_list']
                              ?.firstWhere(
                                (x) => x['concept'] == e['concept'],
                                orElse: () => {'user_share': 0.0},
                              )['user_share'] ??
                          0.0) as num)
                      .toDouble(),
                })
            .toList()
          ..sort((a, b) =>
              (b['amount'] as double).compareTo(a['amount'] as double));
        if (!mounted) return;
        setState(() {
          _items = filtered;
          _loaded = true;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (widget.data['common_expenses'] as num? ?? 0).toDouble();
    final color = AppColors.common;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) {
            setState(() => _expanded = v);
            if (v) _load();
          },
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: _leadingIcon(Icons.group_outlined, color),
          title: Text('Gastos comunes',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color)),
          subtitle: Text(_fmt(total),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color)),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loaded && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Sin gastos comunes registrados.',
                    style: TextStyle(
                        color: Colors.black54, fontSize: 13)),
              )
            else if (_items.isNotEmpty) ...[
              // Cabecera
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Concepto',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                    ),
                    Text('Total',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 60,
                      child: Text('Por socio',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ..._items.map<Widget>((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(e['concept'] as String,
                                  style: const TextStyle(
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 11,
                                      color: Colors.grey[500]),
                                  const SizedBox(width: 3),
                                  Text(
                                    e['user_name'] as String,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(_fmt(e['amount']),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: Text(
                            _fmt(e['user_share']),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🍴 Sección almuerzos
// ---------------------------------------------------------------------------
class _LunchCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LunchCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.lunch;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            _leadingIcon(Icons.restaurant_menu, color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Almuerzos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              _fmt(data['lunch_expenses']),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _neutralColor(data['lunch_expenses']),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 💰 Sección a cuenta (depósitos) con desglose por usuario
// ---------------------------------------------------------------------------
class _DepositsCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int eventId;
  const _DepositsCard({required this.data, required this.eventId});

  @override
  State<_DepositsCard> createState() => _DepositsCardState();
}

class _DepositsCardState extends State<_DepositsCard> {
  bool _expanded = false;
  bool _loadingBreakdown = false;
  bool _breakdownLoaded = false;
  List<Map<String, dynamic>> _breakdown = [];

  Future<void> _loadBreakdown() async {
    if (_breakdownLoaded) return;
    setState(() => _loadingBreakdown = true);
    try {
      final res = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/summary/all-users?eventId=${widget.eventId}'),
      );
      if (res.statusCode == 200) {
        final users =
            List<dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)));
        final List<Map<String, dynamic>> rows = [];
        for (final user in users) {
          final expenses =
              List<dynamic>.from(user['paid_expenses_by_type'] ?? []);
          final entry = expenses.firstWhere(
            (e) => e['expense_type'] == 'A cuenta',
            orElse: () => null,
          );
          if (entry != null) {
            final amount =
                ((entry['total_amount'] ?? 0.0) as num).toDouble();
            if (amount > 0) {
              rows.add({
                'username': user['username'] ?? '?',
                'amount': amount,
              });
            }
          }
        }
        rows.sort((a, b) =>
            (b['amount'] as double).compareTo(a['amount'] as double));
        if (!mounted) return;
        setState(() {
          _breakdown = rows;
          _breakdownLoaded = true;
          _loadingBreakdown = false;
        });
      } else {
        if (mounted) setState(() => _loadingBreakdown = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBreakdown = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.positive;
    final total = (widget.data['total_deposits'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) {
            setState(() => _expanded = v);
            if (v) _loadBreakdown();
          },
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: _leadingIcon(
              Icons.account_balance_wallet_outlined, color),
          title: const Text('Total aportado a cuenta',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(_fmt(total),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color)),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 10),
            if (_loadingBreakdown)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_breakdown.isEmpty && _breakdownLoaded)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ningún usuario ha aportado a cuenta.',
                  style:
                      TextStyle(color: Colors.black54, fontSize: 13),
                ),
              )
            else if (_breakdown.isNotEmpty) ...[
              // Cabecera
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Usuario',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                    ),
                    Text('Aportado',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600])),
                  ],
                ),
              ),
              const Divider(height: 1),
              ..._breakdown.map<Widget>((u) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Text(
                                u['username'] as String,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _fmt(u['amount']),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
