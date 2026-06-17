import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/responsive_grid.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/skeleton_loader.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/screens/edit_lunch_screen.dart';
import 'package:cep_flutter_web/screens/lunch_participants_screen.dart';
import 'package:cep_flutter_web/screens/create_lunch_screen.dart';
import 'package:cep_flutter_web/screens/lunch_expense_list_screen.dart';

class LunchListScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const LunchListScreen({
    required this.userId,
    required this.eventId,
    super.key,
  });

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
    if (!mounted) return;
    setState(() => isLoading = true);
    final url = Uri.parse('$baseUrl/api/lunches?event_id=${widget.eventId}');
    try {
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          lunches = body is List ? body : [];
        });
      } else {
        AppSnackBar.error(context, 'Error al cargar almuerzos');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error de red al cargar almuerzos');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<int> fetchParticipantCount(int lunchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/lunch_participants?lunch_id=$lunchId'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        int total = 0;
        for (final p in data) {
          total += (p['num_people'] ?? 1) as int;
        }
        return total;
      }
    }
    return 0;
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
        builder: (_) => LunchParticipantsScreen(lunchId: lunchId, userId: widget.userId),
      ),
    );
  }

  void _navigateToLunchExpenses(int lunchId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LunchExpenseListScreen(lunchId: lunchId, userId: widget.userId, eventId: widget.eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almuerzos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToCreate,
          ),
        ],
      ),
      body: ResponsiveContainer(
          maxWidth: 1000,
          child: isLoading
              ? const SkeletonList(itemCount: 5)
              : lunches.isEmpty
                  ? EmptyState(
                      icon: Icons.lunch_dining,
                      title: 'No hay almuerzos registrados',
                      message: 'Crea el primer almuerzo para empezar a repartir el coste.',
                      actionLabel: 'Crear almuerzo',
                      actionIcon: Icons.add,
                      onAction: _navigateToCreate,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ResponsiveGrid(
                          children: lunches.map<Widget>((lunch) {
                            final desc = lunch['description'] ?? '';
                            final dateStr = lunch['date'] != null
                                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(lunch['date']))
                                : null;
                            return FutureBuilder<int>(
                              future: fetchParticipantCount(lunch['id']),
                              builder: (context, snapshot) {
                                final comensales = snapshot.hasData
                                    ? '${snapshot.data} comensales'
                                    : 'Cargando...';
                                return StandardCard(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                  child: ListTile(
                                    leading: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.lunch.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.lunch_dining, color: AppColors.lunch, size: 20),
                                    ),
                                    title: Text(
                                      desc,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (dateStr != null) ...[
                                          Icon(Icons.calendar_today,
                                              size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              dateStr,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Icon(Icons.group, size: 12, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            comensales,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      onSelected: (value) {
                                        if (value == 'gastos') _navigateToLunchExpenses(lunch['id']);
                                        if (value == 'comensales') _navigateToParticipants(lunch['id']);
                                        if (value == 'editar') _navigateToEdit(lunch);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'comensales', child: ListTile(leading: Icon(Icons.group, size: 18), title: Text('Comensales'), dense: true)),
                                        PopupMenuItem(value: 'gastos', child: ListTile(leading: Icon(Icons.receipt_long, size: 18), title: Text('Gastos'), dense: true)),
                                        PopupMenuItem(value: 'editar', child: ListTile(leading: Icon(Icons.edit, size: 18), title: Text('Editar'), dense: true)),
                                      ],
                                    ),
                                    onTap: () => _navigateToParticipants(lunch['id']),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
      ),
    );
  }
}
