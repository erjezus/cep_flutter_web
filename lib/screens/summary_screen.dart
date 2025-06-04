import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class SummaryScreen extends StatefulWidget {
  final int userId;
  const SummaryScreen({super.key, required this.userId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double total = 0.0;
  final baseUrl = AppConfig.baseUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTotal();
  }

  void fetchTotal() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('$baseUrl/api/consumptions/total'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": widget.userId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        total = jsonDecode(response.body)['total_today'];
      });
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Resumen del día",style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(24.0),
          child: StandardCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  "Has consumido un total de",
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  "€${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 28,
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
}