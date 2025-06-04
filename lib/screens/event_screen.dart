import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/screens/event_menu_screen.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class EventScreen extends StatefulWidget {
  final int userId;

  EventScreen({required this.userId});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List events = [];
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    print("📡 initState: EventScreen cargado");
    fetchEvents();
  }

  void fetchEvents() async {
    print("⏳ fetchEvents lanzado");
    final response = await http.get(Uri.parse('$baseUrl/api/events'));
    print("📥 Status: ${response.statusCode}");
    print("📥 Body: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        events = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFB71C1C);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Eventos", style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: events.isEmpty
            ? Center(
          child: Text(
            "No hay eventos disponibles",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        )
            : ListView.separated(
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final event = events[index];
            return StandardCard(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventMenuScreen(
                        userId: widget.userId,
                        eventId: event['id'],
                        eventName: event['name'],
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: mainColor.withOpacity(0.1),
                      child: Icon(Icons.event, color: mainColor),
                      radius: 28,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        event['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}