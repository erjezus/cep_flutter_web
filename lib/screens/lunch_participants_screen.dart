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
        SnackBar(content: Text('Error al cargar participantes')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> updateParticipant(int id, int numPeople) async {
    final body = jsonEncode({'id': id, 'num_people': numPeople});
    final url = Uri.parse('$baseUrl/api/lunch_participants');
    final res = await http.put(url, body: body, headers: {'Content-Type': 'application/json'});
    if (res.statusCode == 200) {
      fetchParticipants();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar comensales')),
      );
    }
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
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final p = participants[index];
          final controller = TextEditingController(text: p['num_people'].toString());
          return StandardCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Usuario ID: ${p['user_id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Comensales'),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed >= 0) {
                        updateParticipant(p['id'], parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
