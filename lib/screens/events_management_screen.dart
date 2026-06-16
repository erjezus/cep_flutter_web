import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/services/event_management_service.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/app_dialog.dart';
import 'package:cep_flutter_web/widgets/admin/event_form_dialog.dart';

/// Pantalla de gestión de eventos. Solo accesible para administradores.
class EventsManagementScreen extends StatefulWidget {
  final String currentUserRole;

  const EventsManagementScreen({
    required this.currentUserRole,
    super.key,
  });

  @override
  State<EventsManagementScreen> createState() => _EventsManagementScreenState();
}

class _EventsManagementScreenState extends State<EventsManagementScreen> {
  final _service = EventManagementService();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _filteredEvents = [];

  bool get _isAdmin => widget.currentUserRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    if (_isAdmin) _loadEvents();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _service.listEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredEvents = q.isEmpty
          ? List.of(_events)
          : _events
              .where((e) =>
                  (e['name'] ?? '').toString().toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _create() async {
    final ok = await EventFormDialog.show(context, _service);
    if (ok) {
      AppSnackBar.success(context, 'Evento creado');
      await _loadEvents();
    }
  }

  Future<void> _edit(Map<String, dynamic> event) async {
    final ok = await EventFormDialog.show(context, _service, event: event);
    if (ok) {
      AppSnackBar.success(context, 'Evento actualizado');
      await _loadEvents();
    }
  }

  Future<void> _delete(Map<String, dynamic> event) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿Eliminar evento?',
      message: '¿Estás seguro de que quieres eliminar "${event['name']}"? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteEvent(event['id'] as int);
      if (!mounted) return;
      AppSnackBar.success(context, 'Evento eliminado');
      await _loadEvents();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de eventos')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Acceso denegado',
          message: 'Solo los administradores pueden acceder a esta sección.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _isLoading ? null : _loadEvents,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ResponsiveContainer(
        maxWidth: 1000,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'No se pudieron cargar los eventos',
        message: _error,
        actionLabel: 'Reintentar',
        actionIcon: Icons.refresh,
        onAction: _loadEvents,
      );
    }
    if (_filteredEvents.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: _events.isEmpty ? 'No hay eventos' : 'Sin resultados',
        message: _events.isEmpty
            ? 'Crea el primer evento con el botón inferior.'
            : 'Prueba con otro término de búsqueda.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 720) {
            return _buildTable();
          }
          return _buildCards();
        },
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Creado')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _filteredEvents.map((e) {
                return DataRow(
                  onSelectChanged: (_) => _edit(e),
                  cells: [
                    DataCell(Text('${e['id']}')),
                    DataCell(Text((e['name'] ?? '').toString())),
                    DataCell(Text(_formatDate(e['created_at']))),
                    DataCell(_statusChip(e['status'])),
                    DataCell(_rowActions(e)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCards() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _filteredEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = _filteredEvents[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _edit(e),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.event, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                (e['name'] ?? '').toString(),
                                overflow: TextOverflow.ellipsis,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusChip(e['status']),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(e['created_at']),
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _rowActions(e),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    final isActive = s == 'active';
    final color = isActive ? AppColors.positive : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVO' : (s.isEmpty ? 'SIN ESTADO' : s.toUpperCase()),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _rowActions(Map<String, dynamic> e) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: Icon(Icons.edit, color: AppColors.blue),
          onPressed: () => _edit(e),
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _delete(e),
        ),
      ],
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return parsed.toLocal().toString().split(' ')[0];
  }
}

