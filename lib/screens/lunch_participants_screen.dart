import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class LunchParticipantsScreen extends StatefulWidget {
  final int lunchId;

  const LunchParticipantsScreen({required this.lunchId, super.key});

  @override
  State<LunchParticipantsScreen> createState() => _LunchParticipantsScreenState();
}

class _LunchParticipantsScreenState extends State<LunchParticipantsScreen> {
  List participants = [];
  bool isLoading = false;
  final baseUrl = AppConfig.baseUrl;
  final mainColor = const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    fetchParticipants();
  }

  Future<void> fetchParticipants() async {
    setState(() => isLoading = true);
    final url = Uri.parse('$baseUrl/api/lunch_participants?lunch_id=${widget.lunchId}');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      setState(() {
        participants = jsonDecode(res.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar participantes')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> updateParticipant(int id, int numPeople) async {
    final body = jsonEncode({'id': id, 'num_people': numPeople});
    final url = Uri.parse('$baseUrl/api/lunch_participants');
    final res = await http.put(url, body: body, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar comensales')),
      );
    }
  }

  int get totalComensales {
    return participants.fold<int>(
      0,
          (sum, p) => sum + ((p['num_people'] ?? 0) as num).toInt(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Participantes del almuerzo', style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : participants.isEmpty
          ? const Center(child: Text('No hay participantes'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: participants.length + 1, // extra para el total
        itemBuilder: (context, index) {
          if (index == participants.length) {
            return StandardCard(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total de comensales: $totalComensales',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          final p = participants[index];
          return StandardCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('${p['username']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: p['num_people'] > 0
                          ? () {
                        setState(() => p['num_people']--);
                        updateParticipant(p['id'], p['num_people']);
                      }
                          : null,
                    ),
                    Text('${p['num_people']}', style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() => p['num_people']++);
                        updateParticipant(p['id'], p['num_people']);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
