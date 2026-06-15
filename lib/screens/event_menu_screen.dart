import 'package:flutter/material.dart';
import 'package:cep_flutter_web/screens/product_screen.dart';
import 'package:cep_flutter_web/screens/consumption_screen.dart';
import 'package:cep_flutter_web/screens/upload_expense_screen.dart';
import 'package:cep_flutter_web/screens/expense_list_screen.dart';
import 'package:cep_flutter_web/screens/common_summary_screen.dart';
import 'package:cep_flutter_web/screens/lunch_list_screen.dart';
import 'package:cep_flutter_web/screens/all_users_summary_screen.dart';
import 'package:cep_flutter_web/screens/event_products_screen.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';

class EventMenuScreen extends StatelessWidget {
  final int userId;
  final String userName;
  final int eventId;
  final String eventName;

  const EventMenuScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.eventId,
    required this.eventName,
  });

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
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
            ExpenseListScreen(userId: userId, eventId: eventId)),
      ),
      _MenuAction(
        icon: Icons.lunch_dining,
        label: 'Almuerzos',
        color: AppColors.lunch,
        onTap: () => _go(context,
            LunchListScreen(eventId: eventId, userId: userId)),
      ),
      _MenuAction(
        icon: Icons.sell,
        label: 'Precios',
        color: AppColors.prices,
        onTap: () => _go(context,
            EventProductsScreen(eventId: eventId, eventName: eventName)),
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: Text(eventName)),
      body: ResponsiveContainer(
        maxWidth: 800,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ActionCard(action: actions[index]),
                  childCount: actions.length,
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
            '¡Hola, $userName! 👋',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué quieres hacer en $eventName?',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
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

class _ActionCard extends StatelessWidget {
  final _MenuAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 30, color: action.color),
                ),
                const SizedBox(height: 12),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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

