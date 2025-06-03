import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SummaryScreen extends StatefulWidget {
  final int userId;
  const SummaryScreen({super.key, required this.userId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    fetchTotal();
  }

  void fetchTotal() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/consumptions/total'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": widget.userId}),
    );
    if (response.statusCode == 200) {
      setState(() {
        total = jsonDecode(response.body)['total_today'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Resumen del día")),
      body: Center(
        child: Text("Has consumido un total de €${total.toStringAsFixed(2)} hoy."),
      ),
    );
  }
}
