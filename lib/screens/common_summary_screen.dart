import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/animated_count.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

class CommonSummaryScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const CommonSummaryScreen({required this.userId, required this.eventId, super.key});

  @override
  State<CommonSummaryScreen> createState() => _CommonSummaryScreenState();
}

class _CommonSummaryScreenState extends State<CommonSummaryScreen> {
  double totalFood = 0.0;
  double totalDrink = 0.0;
  double globalDrinkConsumed = 0.0;
  double globalDrinkSpent = 0.0;
  double globalFoodConsumed = 0.0;
  double globalFoodSpent = 0.0;
  double depositExpenses = 0.0;
  double totalPaidExpenses = 0.0;

  double totalCommonExpenses = 0.0;
  int userCount = 0;
  double commonPerUser = 0.0;

  List<Map<String, dynamic>> lunchCosts = [];

  bool isLoading = false;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final foodRes = await http.get(Uri.parse('$baseUrl/api/consumptions/total/event?userId=${widget.userId}&eventId=${widget.eventId}&type=Comida'));
      final drinkRes = await http.get(Uri.parse('$baseUrl/api/consumptions/total/event?userId=${widget.userId}&eventId=${widget.eventId}&type=Bebida'));
      final globalDrinkRes = await http.get(Uri.parse('$baseUrl/api/summary/drink?eventId=${widget.eventId}'));
      final globalFoodRes = await http.get(Uri.parse('$baseUrl/api/summary/food?eventId=${widget.eventId}'));
      final commonExpensesRes = await http.get(Uri.parse('$baseUrl/api/summary/common?eventId=${widget.eventId}'));
      final usersRes = await http.get(Uri.parse('$baseUrl/api/users/count'));
      final lunchCostsRes = await http.get(Uri.parse('$baseUrl/api/summary/lunch-costs?eventId=${widget.eventId}&userId=${widget.userId}'));
      final depositRes = await http.get(Uri.parse('$baseUrl/api/summary/deposit?eventId=${widget.eventId}&userId=${widget.userId}'));
      final paidExpensesRes = await http.get(Uri.parse('$baseUrl/api/summary/paid?eventId=${widget.eventId}&userId=${widget.userId}'));

      if (foodRes.statusCode == 200 &&
          drinkRes.statusCode == 200 &&
          globalDrinkRes.statusCode == 200 &&
          globalFoodRes.statusCode == 200 &&
          commonExpensesRes.statusCode == 200 &&
          usersRes.statusCode == 200 &&
          lunchCostsRes.statusCode == 200 &&
          depositRes.statusCode == 200 &&
          paidExpensesRes.statusCode == 200) {

        final foodData = jsonDecode(foodRes.body);
        final drinkData = jsonDecode(drinkRes.body);
        final globalDrinkData = jsonDecode(globalDrinkRes.body);
        final globalFoodData = jsonDecode(globalFoodRes.body);
        final commonData = jsonDecode(commonExpensesRes.body);
        final usersData = jsonDecode(usersRes.body);
        final lunchData = jsonDecode(utf8.decode(lunchCostsRes.bodyBytes));
        final depositData = jsonDecode(depositRes.body);
        final paidData = jsonDecode(paidExpensesRes.body);

        final totalCommon = (commonData['total_common'] ?? 0).toDouble();
        final users = (usersData['total_users'] ?? 0).toInt();

        setState(() {
          totalFood = (foodData['total'] ?? 0).toDouble();
          totalDrink = (drinkData['total'] ?? 0).toDouble();
          globalDrinkConsumed = (globalDrinkData['total_consumed'] ?? 0).toDouble();
          globalDrinkSpent = (globalDrinkData['total_spent'] ?? 0).toDouble();
          globalFoodConsumed = (globalFoodData['total_consumed'] ?? 0).toDouble();
          globalFoodSpent = (globalFoodData['total_spent'] ?? 0).toDouble();
          depositExpenses = (depositData['total_deposit'] ?? 0).toDouble();
          totalPaidExpenses = (paidData['total_paid'] ?? 0).toDouble();

          totalCommonExpenses = totalCommon;
          userCount = users;
          commonPerUser = users > 0 ? totalCommon / users : 0.0;

          lunchCosts = List<Map<String, dynamic>>.from(lunchData);
        });
      } else {
        throw Exception("Error al cargar los datos");
      }
    } catch (e) {
      AppSnackBar.error(context, "Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildRow(String label, String value, {
    bool highlight = false,
    IconData? icon,
    Color? overrideColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) Icon(icon, size: 18),
                if (icon != null) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: highlight ? 18 : 16,
                color: overrideColor ?? (highlight ? Colors.red[700] : Colors.black),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  Widget buildSection(String title, List<Widget> content, {IconData? icon, bool initiallyExpanded = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: icon != null
                ? CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  )
                : null,
            title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            children: content,
          ),
        ),
      ),
    );
  }

  /// Tarjeta destacada con el resultado final.
  Widget buildHeroCard(double totalFinal) {
    final bool debe = totalFinal > 0;
    final Color heroColor = debe ? AppColors.negative : AppColors.positive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [heroColor.withOpacity(0.9), heroColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: heroColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(debe ? Icons.account_balance_wallet : Icons.celebration,
              color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            debe ? "Te toca poner" : "Te sobra",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          AnimatedCount(
            value: totalFinal.abs(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final total = totalFood + totalDrink;
    final diferenciaBebida = globalDrinkSpent - globalDrinkConsumed;
    final diferenciaComida = globalFoodSpent - globalFoodConsumed;
    final perdidaBebidaUsuario = userCount > 0 ? diferenciaBebida / userCount : 0.0;
    final perdidaComidaUsuario = userCount > 0 ? diferenciaComida / userCount : 0.0;
    final costeUsuarioAlmuerzos = lunchCosts.fold<double>(0.0, (sum, item) => sum + (item['user_cost'] ?? 0));
    final totalFinal = total + costeUsuarioAlmuerzos + perdidaBebidaUsuario + perdidaComidaUsuario + commonPerUser - depositExpenses - totalPaidExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de gastos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildHeroCard(totalFinal),
                    const SizedBox(height: 8),
                    buildSection("Resumen personal", [
                      buildRow("Comida", "€${totalFood.toStringAsFixed(2)}", icon: Icons.restaurant),
                      buildRow("Bebida", "€${totalDrink.toStringAsFixed(2)}", icon: Icons.local_drink),
                      buildRow("Total consumido", "€${total.toStringAsFixed(2)}", highlight: true, icon: Icons.calculate),
                    ], icon: Icons.person, initiallyExpanded: true),
                    buildSection("Coste por almuerzo", (lunchCosts.isEmpty
                ? [
              {
                'description': 'Almuerzo',
                'total_amount': 0.0,
                'total_people': 0,
                'user_people': 0,
                'cost_per_plate': 0.0,
                'user_cost': 0.0,
              }
            ]
                : lunchCosts).map((lunch) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lunch['description'] ?? 'Almuerzo', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  buildRow("Importe total", "€${(lunch['total_amount'] ?? 0).toStringAsFixed(2)}"),
                  buildRow("Personas", "${lunch['total_people'] ?? 0}"),
                  buildRow("Comensales del usuario", "${lunch['user_people'] ?? 0}"),
                  buildRow("Coste por plato", "€${(lunch['cost_per_plate'] ?? 0).toStringAsFixed(2)}"),
                  buildRow("Coste usuario", "€${(lunch['user_cost'] ?? 0).toStringAsFixed(2)}", highlight: true),
                  const Divider(),
                ],
              );
            }).toList(), icon: Icons.lunch_dining),

            buildSection("Resumen general bebida", [
              buildRow("Total comprado", "€${globalDrinkSpent.toStringAsFixed(2)}", icon: Icons.shopping_cart),
              buildRow("Total consumido", "€${globalDrinkConsumed.toStringAsFixed(2)}", icon: Icons.local_bar),
              buildRow("Diferencia", "€${diferenciaBebida.toStringAsFixed(2)}", icon: Icons.trending_down),
              buildRow("Pérdida por usuario", "€${perdidaBebidaUsuario.toStringAsFixed(2)}", highlight: true, overrideColor: perdidaBebidaUsuario > 0 ? Colors.red : Colors.green),
            ], icon: Icons.local_bar),
            buildSection("Resumen general comida", [
              buildRow("Total comprado", "€${globalFoodSpent.toStringAsFixed(2)}", icon: Icons.shopping_cart),
              buildRow("Total consumido", "€${globalFoodConsumed.toStringAsFixed(2)}", icon: Icons.fastfood),
              buildRow("Diferencia", "€${diferenciaComida.toStringAsFixed(2)}", icon: Icons.trending_down),
              buildRow("Pérdida por usuario", "€${perdidaComidaUsuario.toStringAsFixed(2)}", highlight: true, overrideColor: perdidaComidaUsuario > 0 ? Colors.red : Colors.green),
            ], icon: Icons.restaurant),
            buildSection("Gastos comunes", [
              buildRow("Total común", "€${totalCommonExpenses.toStringAsFixed(2)}"),
              buildRow("Usuarios registrados", "$userCount"),
              buildRow("Parte por usuario", "€${commonPerUser.toStringAsFixed(2)}", highlight: true),
            ], icon: Icons.group),
            buildSection("Gastos a cuenta", [
              buildRow("Total aportado por el usuario", "€${depositExpenses.toStringAsFixed(2)}", icon: Icons.account_balance_wallet),
            ], icon: Icons.account_balance_wallet),
            buildSection("Gastos pagados", [
              buildRow("Total marcado como pagado", "€${totalPaidExpenses.toStringAsFixed(2)}", icon: Icons.check_circle_outline, highlight: true),
            ], icon: Icons.check_circle),
            buildSection("Resumen final", [
              buildRow("Total consumido", "€${total.toStringAsFixed(2)}", icon: Icons.local_dining),
              buildRow("Coste usuario almuerzos", "€${costeUsuarioAlmuerzos.toStringAsFixed(2)}", icon: Icons.lunch_dining),
              buildRow("Pérdida por usuario (bebida)", "€${perdidaBebidaUsuario.toStringAsFixed(2)}", icon: Icons.local_bar),
              buildRow("Pérdida por usuario (comida)", "€${perdidaComidaUsuario.toStringAsFixed(2)}", icon: Icons.restaurant),
              buildRow("Parte por usuario de gastos comunes", "€${commonPerUser.toStringAsFixed(2)}", icon: Icons.group),
              buildRow("Gastos a cuenta", "-€${depositExpenses.toStringAsFixed(2)}", icon: Icons.account_balance_wallet),
              buildRow("Gastos pagados", "-€${totalPaidExpenses.toStringAsFixed(2)}", icon: Icons.check_circle_outline),
              const Divider(),
              buildRow("Total final", "€${totalFinal.toStringAsFixed(2)}", highlight: true, icon: Icons.summarize),
            ], icon: Icons.summarize, initiallyExpanded: true),
          ],
        ),
              ),
            ),
    );
  }
}
