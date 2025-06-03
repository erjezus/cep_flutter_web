import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/screens/event_menu_screen.dart';
import 'package:cep_flutter_web/config/config.dart';

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
    final Color mainColor = Color(0xFFD32F2F);

    return Scaffold(
      appBar: AppBar(
        title: Text("Eventos"),
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: events.isEmpty
            ? Center(child: Text("No hay eventos disponibles"))
            : ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.only(bottom: 16),
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}