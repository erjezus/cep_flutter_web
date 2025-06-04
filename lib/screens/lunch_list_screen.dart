import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/screens/edit_lunch_screen.dart';
import 'package:cep_flutter_web/screens/lunch_participants_screen.dart';
import 'package:cep_flutter_web/screens/create_lunch_screen.dart';

class LunchListScreen extends StatefulWidget {
  final int eventId;

  const LunchListScreen({required this.eventId, super.key});

  @override
  State<LunchListScreen> createState() => _LunchListScreenState();
}

class _LunchListScreenState extends State<LunchListScreen> {
  List lunches = [];
  bool isLoading = false;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchLunches();
  }

  Future<void> fetchLunches() async {
    setState(() => isLoading = true);
    final url = Uri.parse('$baseUrl/api/lunches?event_id=${widget.eventId}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      setState(() {
        lunches = body is List ? body : [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar almuerzos')),
      );
    }
    setState(() => isLoading = false);
  }

  void _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateLunchScreen(eventId: widget.eventId)),
    );
    if (result == true) fetchLunches();
  }

  void _navigateToEdit(Map lunch) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditLunchScreen(
          lunchId: lunch['id'],
          initialDate: DateTime.parse(lunch['date']),
          initialDescription: lunch['description'] ?? '',
        ),
      ),
    );
    if (result == true) fetchLunches();
  }

  void _navigateToParticipants(int lunchId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LunchParticipantsScreen(lunchId: lunchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Almuerzos', style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToCreate,
          ),
        ],
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : lunches.isEmpty
            ? const Center(child: Text('No hay almuerzos registrados'))
            : ListView(
          padding: const EdgeInsets.all(16),
          children: lunches.map((lunch) {
            final date = lunch['date']?.toString().split('T')[0] ?? '';
            final desc = lunch['description'] ?? '';
            return StandardCard(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                title: Text(
                  desc,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Fecha: $date'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.group),
                      tooltip: 'Comensales',
                      onPressed: () => _navigateToParticipants(lunch['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar',
                      onPressed: () => _navigateToEdit(lunch),
                    ),
                  ],
                ),
                onTap: () => _navigateToParticipants(lunch['id']),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
