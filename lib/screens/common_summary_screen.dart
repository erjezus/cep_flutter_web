import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class CommonSummaryScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const CommonSummaryScreen({required this.userId, required this.eventId, super.key});

  @override
  State<CommonSummaryScreen> createState() => _CommonSummaryScreenState();
}

class _CommonSummaryScreenState extends State<CommonSummaryScreen> {
  double totalCommon = 0.0;
  double perUser = 0.0;
  double userTotal = 0.0;
  int userCount = 0;
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
      final commonRes = await http.get(
        Uri.parse('$baseUrl/api/expenses/common?eventId=${widget.eventId}'),
      );
      final userRes = await http.get(
        Uri.parse('$baseUrl/api/users/count'),
      );
      final consumptionRes = await http.get(
        Uri.parse('$baseUrl/api/consumptions/total/event?userId=${widget.userId}&eventId=${widget.eventId}'),
      );

      if (commonRes.statusCode == 200 && userRes.statusCode == 200 && consumptionRes.statusCode == 200) {
        final commonData = jsonDecode(commonRes.body);
        final userData = jsonDecode(userRes.body);
        final consumptionData = jsonDecode(consumptionRes.body);

        final total = (commonData['total_common'] ?? 0).toDouble();
        final users = (userData['total_users'] ?? 0).toInt();
        final consumption = (consumptionData['total'] ?? 0).toDouble();

        setState(() {
          totalCommon = total;
          userCount = users;
          userTotal = consumption;
          perUser = users > 0 ? total / users : 0.0;
        });
      } else {
        throw Exception('Código de estado no válido');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        totalCommon = 0.0;
        userTotal = 0.0;
        perUser = 0.0;
        userCount = 0;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget buildInfoCard(String title, String value) {
    return StandardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Resumen de gastos',style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildInfoCard("Total de gastos comunes", "€${totalCommon.toStringAsFixed(2)}"),
            buildInfoCard("Tus consumiciones personales", "€${userTotal.toStringAsFixed(2)}"),
            buildInfoCard("Usuarios registrados", "$userCount"),
            buildInfoCard("Parte proporcional común", "€${perUser.toStringAsFixed(2)}"),
            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 12),
            buildInfoCard("Total a pagar", "€${(perUser + userTotal).toStringAsFixed(2)}"),
          ],
        ),
      ),
    );
  }
}
