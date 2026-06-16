import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/screens/event_menu_screen.dart';
import 'package:cep_flutter_web/screens/users_management_screen.dart';
import 'package:cep_flutter_web/screens/events_management_screen.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/responsive_grid.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';

class EventScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userRole;

  EventScreen({
    required this.userId,
    required this.userName,
    this.userRole = 'USER',
  });

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List events = [];
  bool _isLoading = true;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/events'));
      if (response.statusCode == 200) {
        setState(() {
          events = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (_) {
      // se mantiene la lista vacía; la UI muestra el estado vacío
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAdmin => widget.userRole.toUpperCase() == 'ADMIN';

  /// Eventos visibles según el rol:
  /// - Admin: todos los eventos.
  /// - Resto: solo los que tienen `status == 'active'`.
  List get _visibleEvents {
    if (_isAdmin) return events;
    return events
        .where((e) => (e['status'] ?? '').toString().toLowerCase() == 'active')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = AppColors.primary;
    final visibleEvents = _visibleEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eventos"),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Hero(
            tag: 'app-logo',
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset('assets/logo.png'),
              ),
            ),
          ),
        ),
        actions: [
          if (widget.userRole.toUpperCase() == 'ADMIN') ...[
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              tooltip: 'Gestión de eventos',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventsManagementScreen(
                      currentUserRole: widget.userRole,
                    ),
                  ),
                );
                fetchEvents();
              },
            ),
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Gestión de usuarios',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsersManagementScreen(
                      currentUserId: widget.userId,
                      currentUserRole: widget.userRole,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 1000,
        child: _isLoading
            ? const SkeletonList(itemCount: 5)
            : RefreshIndicator(
                onRefresh: fetchEvents,
                child: visibleEvents.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.event_busy,
                            title: "No hay eventos disponibles",
                            message: "Cuando se cree un evento aparecerá aquí.",
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          ResponsiveGrid(
                            children: visibleEvents.map<Widget>((event) {
                              return StandardCard(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                    builder: (_) => EventMenuScreen(
                                      userId: widget.userId,
                                      userName: widget.userName,
                                      userRole: widget.userRole,
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event['name'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            if (event['created_at'] != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today,
                                                      size: 13, color: Colors.grey[500]),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    event['created_at'].toString().split('T')[0],
                                                    style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600]),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}