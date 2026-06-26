import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';

class EventOverviewScreen extends StatefulWidget {
  final int eventId;
  final String? eventName;

  const EventOverviewScreen({
    required this.eventId,
    this.eventName,
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
                          _TotalsCard(data: _data!),
                          _DrinkCard(data: _data!),
                          _FoodCard(data: _data!),
                          _CommonExpensesCard(data: _data!),
                          _LunchCard(data: _data!),
                          _DepositsCard(data: _data!),
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

Widget _sectionHeader(String emoji, String title, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
// 🍺 Sección bebida
// ---------------------------------------------------------------------------
class _DrinkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DrinkCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🍺', 'Bebida', AppColors.primary),
          _dataRow('Gastado en bebida', _fmt(data['drink_expenses'])),
          _dataRow('Consumido registrado', _fmt(data['drink_consumed'])),
          _dataRow('Pérdida bebida', _fmt(data['drink_loss']),
              valueColor: _lossColor(data['drink_loss'])),
          _dataRow('Pérdida por socio', _fmt(data['drink_loss_per_user']),
              valueColor: _lossColor(data['drink_loss_per_user'])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🍽️ Sección comida
// ---------------------------------------------------------------------------
class _FoodCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FoodCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🍽️', 'Comida', AppColors.food),
          _dataRow('Gastado en comida', _fmt(data['food_expenses'])),
          _dataRow('Consumido registrado', _fmt(data['food_consumed'])),
          _dataRow('Pérdida comida', _fmt(data['food_loss']),
              valueColor: _lossColor(data['food_loss'])),
          _dataRow('Pérdida por socio', _fmt(data['food_loss_per_user']),
              valueColor: _lossColor(data['food_loss_per_user'])),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 👥 Sección gastos comunes (expandible)
// ---------------------------------------------------------------------------
class _CommonExpensesCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _CommonExpensesCard({required this.data});

  @override
  State<_CommonExpensesCard> createState() => _CommonExpensesCardState();
}

class _CommonExpensesCardState extends State<_CommonExpensesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final total = (widget.data['common_expenses'] as num? ?? 0).toDouble();
    final items =
        (widget.data['common_expenses_list'] as List? ?? []);
    final color = AppColors.common;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
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
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: Text('👥',
              style: TextStyle(fontSize: 20,
                  color: color)),
          title: Text(
            'Gastos comunes',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color),
          ),
          subtitle: Text(
            _fmt(total),
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: color),
          ),
          children: items.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Sin gastos comunes registrados.',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                  )
                ]
              : [
                  // Cabecera de la tabla
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
                        Text('Por socio',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...items.map<Widget>((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e['concept'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              _fmt(e['amount']),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
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
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Text('🍴', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Almuerzos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.lunch,
              ),
            ),
          ),
          Text(
            _fmt(data['lunch_expenses']),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _neutralColor(data['lunch_expenses']),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 💰 Sección a cuenta (depósitos)
// ---------------------------------------------------------------------------
class _DepositsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DepositsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          const Text('💰', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Total aportado a cuenta',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            _fmt(data['total_deposits']),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.positive,
            ),
          ),
        ],
      ),
    );
  }
}
