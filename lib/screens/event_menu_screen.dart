import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/screens/product_screen.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';
import 'package:cep_flutter_web/screens/upload_expense_screen.dart';
import 'package:cep_flutter_web/screens/expense_list_screen.dart';
import 'package:cep_flutter_web/screens/common_summary_screen.dart';
import 'package:cep_flutter_web/screens/lunch_list_screen.dart';
import 'package:cep_flutter_web/screens/all_users_summary_screen.dart';
import 'package:cep_flutter_web/screens/event_products_screen.dart';
import 'package:cep_flutter_web/screens/users_management_screen.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';

class EventMenuScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;
  final int eventId;
  final String eventName;

  const EventMenuScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.eventId,
    required this.eventName,
    this.userRole = 'USER',
  });

  @override
  State<EventMenuScreen> createState() => _EventMenuScreenState();
}

class _EventMenuScreenState extends State<EventMenuScreen> {
  bool _unpaidChecked = false;
  int _unpaidCount = 0;
  double _unpaidTotal = 0.0;
  bool _unpaidDismissed = false;

  bool get _isAdmin => widget.userRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _checkUnpaidExpenses();
  }

  /// Comprueba si existen gastos sin pagar de cualquier usuario en el evento,
  /// incluyendo los gastos asociados a los almuerzos.
  Future<void> _checkUnpaidExpenses() async {
    try {
      // Mapa de gastos únicos por id para evitar contar dos veces el mismo
      // gasto (los gastos de almuerzo pueden aparecer también en la consulta
      // general de gastos del evento).
      final Map<dynamic, dynamic> uniqueExpenses = {};

      // 1) Gastos generales del evento.
      final res = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/expenses?eventId=${widget.eventId}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is List) {
          for (final e in data) {
            uniqueExpenses[e['id']] = e;
          }
        }
      }

      // 2) Gastos de cada almuerzo del evento.
      await _collectLunchExpenses(uniqueExpenses);

      int count = 0;
      double total = 0.0;
      for (final e in uniqueExpenses.values) {
        if (!_asBool(e['paid'])) {
          count++;
          total += (double.tryParse('${e['amount']}') ?? 0.0);
        }
      }

      if (!mounted) return;
      setState(() {
        _unpaidChecked = true;
        _unpaidCount = count;
        _unpaidTotal = total;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _unpaidChecked = true);
    }
  }

  /// Obtiene los gastos de todos los almuerzos del evento y los añade al mapa
  /// de gastos únicos (clave: id del gasto).
  Future<void> _collectLunchExpenses(Map<dynamic, dynamic> uniqueExpenses) async {
    try {
      final lunchesRes = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/lunches?event_id=${widget.eventId}'),
      );
      if (lunchesRes.statusCode != 200) return;

      final lunches = jsonDecode(utf8.decode(lunchesRes.bodyBytes));
      if (lunches is! List) return;

      for (final lunch in lunches) {
        final lunchId = lunch['id'];
        if (lunchId == null) continue;
        final expRes = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/lunches/expenses?lunchId=$lunchId'),
        );
        if (expRes.statusCode != 200) continue;
        final expData = jsonDecode(utf8.decode(expRes.bodyBytes));
        if (expData is! List) continue;
        for (final e in expData) {
          uniqueExpenses[e['id']] = e;
        }
      }
    } catch (_) {
      // Si falla la carga de almuerzos, mantenemos solo los gastos generales.
    }
  }

  /// Normaliza el campo `paid` que puede llegar como bool, num o string.
  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1';
    }
    return false;
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final userName = widget.userName;
    final userRole = widget.userRole;
    final eventId = widget.eventId;
    final eventName = widget.eventName;
    final actions = <_MenuAction>[
      _MenuAction(
        icon: Icons.local_bar,
        label: 'Consumir',
        color: AppColors.primary,
        onTap: () => _go(context,
            ProductScreen(userId: userId, userName: userName, eventId: eventId)),
      ),
      _MenuAction(
        icon: Icons.receipt_long,
        label: 'Mis consumiciones',
        color: Colors.grey.shade800,
        onTap: () => _go(context,
            ConsumptionScreen(userId: userId, userName: userName, eventId: eventId)),
      ),
      _MenuAction(
        icon: Icons.add_circle,
        label: 'Añadir gasto',
        color: AppColors.food,
        onTap: () => _go(context,
            UploadExpenseScreen(userId: userId, eventId: eventId)),
      ),
      _MenuAction(
        icon: Icons.table_chart,
        label: 'Ver gastos',
        color: AppColors.expenses,
        onTap: () => _go(context,
            ExpenseListScreen(userId: userId, eventId: eventId, userRole: userRole)),
      ),
      _MenuAction(
        icon: Icons.lunch_dining,
        label: 'Almuerzos',
        color: AppColors.lunch,
        onTap: () => _go(context,
            LunchListScreen(eventId: eventId, userId: userId)),
      ),
      _MenuAction(
        icon: Icons.summarize,
        label: 'Resumen total',
        color: AppColors.blue,
        onTap: () => _go(context,
            CommonSummaryScreen(userId: userId, eventId: eventId)),
      ),
      _MenuAction(
        icon: Icons.people_alt,
        label: 'Resumen por usuario',
        color: AppColors.users,
        onTap: () => _go(context,
            AllUsersSummaryScreen(eventId: eventId)),
      ),
    ];

    if (_isAdmin) {
      actions.add(
        _MenuAction(
          icon: Icons.sell,
          label: 'Precios',
          color: AppColors.prices,
          onTap: () => _go(context,
              EventProductsScreen(eventId: eventId, eventName: eventName)),
        ),
      );
      actions.add(
        _MenuAction(
          icon: Icons.manage_accounts,
          label: 'Gestión de usuarios',
          color: AppColors.primaryDark,
          onTap: () => _go(
            context,
            UsersManagementScreen(
              currentUserId: userId,
              currentUserRole: userRole,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: Text(eventName)),
      body: ResponsiveContainer(
        maxWidth: 800,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_unpaidChecked && _unpaidCount > 0 && !_unpaidDismissed)
              SliverToBoxAdapter(child: _buildUnpaidBanner()),
            // Lista de navegación agrupada en una sola tarjeta
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        _ActionTile(action: actions[i]),
                        if (i < actions.length - 1)
                          const Divider(height: 1, indent: 68, endIndent: 0),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, ${widget.userName}! 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué quieres hacer en ${widget.eventName}?',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Aviso visible cuando existen gastos sin pagar en el evento.
  Widget _buildUnpaidBanner() {
    final plural = _unpaidCount == 1 ? 'gasto' : 'gastos';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.negative.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.negative.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.negative.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.negative, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hay $_unpaidCount $plural sin pagar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.negative,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Importe pendiente: €${_unpaidTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.negative,
                    ),
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('Ver gastos sin pagar'),
                    onPressed: () => _go(
                      context,
                      ExpenseListScreen(
                        userId: widget.userId,
                        eventId: widget.eventId,
                        userRole: widget.userRole,
                        initialUnpaidOnly: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Descartar',
              icon: const Icon(Icons.close, size: 20),
              color: Colors.grey[600],
              onPressed: () => setState(() => _unpaidDismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ActionTile extends StatelessWidget {
  final _MenuAction action;

  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icono en contenedor cuadrado redondeado (pequeño y discreto)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(action.icon, size: 19, color: action.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

