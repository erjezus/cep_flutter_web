import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/models/user.dart';
import 'package:cep_flutter_web/services/user_management_service.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/empty_state.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';
import 'package:cep_flutter_web/widgets/app_dialog.dart';
import 'package:cep_flutter_web/widgets/admin/create_user_dialog.dart';
import 'package:cep_flutter_web/widgets/admin/edit_user_dialog.dart';
import 'package:cep_flutter_web/widgets/admin/change_role_dialog.dart';

/// Pantalla de gestión de usuarios. Solo accesible para administradores.
class UsersManagementScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUserRole;

  const UsersManagementScreen({
    required this.currentUserId,
    required this.currentUserRole,
    super.key,
  });

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  late final UserManagementService _service;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<User> _users = [];
  List<User> _filteredUsers = [];

  bool get _isAdmin => widget.currentUserRole.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _service = UserManagementService(
      adminUserId: widget.currentUserId,
      adminUserRole: widget.currentUserRole,
    );
    if (_isAdmin) _loadUsers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _service.listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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
      _filteredUsers = q.isEmpty
          ? List.of(_users)
          : _users
              .where((u) =>
                  u.username.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _create() async {
    final ok = await CreateUserDialog.show(context, _service);
    if (ok) {
      AppSnackBar.success(context, 'Usuario creado');
      await _loadUsers();
    }
  }

  Future<void> _edit(User user) async {
    final ok = await EditUserDialog.show(context, _service, user);
    if (ok) {
      AppSnackBar.success(context, 'Usuario actualizado');
      await _loadUsers();
    }
  }

  Future<void> _changeRole(User user) async {
    final ok = await ChangeRoleDialog.show(context, _service, user);
    if (ok) {
      AppSnackBar.success(context, 'Rol actualizado');
      await _loadUsers();
    }
  }

  Future<void> _delete(User user) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿Eliminar usuario?',
      message: '¿Estás seguro de que quieres eliminar a ${user.username}? '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_outline,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _service.deleteUser(user.id);
      if (!mounted) return;
      AppSnackBar.success(context, 'Usuario eliminado');
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de usuarios')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Acceso denegado',
          message: 'Solo los administradores pueden acceder a esta sección.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _isLoading ? null : _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario',
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
                    hintText: 'Buscar por username o email',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
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
        title: 'No se pudieron cargar los usuarios',
        message: _error,
        actionLabel: 'Reintentar',
        actionIcon: Icons.refresh,
        onAction: _loadUsers,
      );
    }
    if (_filteredUsers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: _users.isEmpty ? 'No hay usuarios' : 'Sin resultados',
        message: _users.isEmpty
            ? 'Crea el primer usuario con el botón inferior.'
            : 'Prueba con otro término de búsqueda.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas anchas mostramos una DataTable; en estrechas,
          // tarjetas apiladas para que sea legible en móvil.
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
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rol')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _filteredUsers.map((u) {
                return DataRow(
                  onSelectChanged: (_) => _edit(u),
                  cells: [
                    DataCell(Text('${u.id}')),
                    DataCell(Text(u.username)),
                    DataCell(Text(u.email)),
                    DataCell(_roleChip(u.role)),
                    DataCell(_rowActions(u)),
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
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = _filteredUsers[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _edit(u),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.users.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.users, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                                u.username,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _roleChip(u.role),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          u.email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _rowActions(u),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _roleChip(String role) {
    final isAdmin = role.toUpperCase() == 'ADMIN';
    final color = isAdmin ? AppColors.primary : AppColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Widget _rowActions(User u) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Editar',
          icon: Icon(Icons.edit, color: AppColors.blue),
          onPressed: () => _edit(u),
        ),
        IconButton(
          tooltip: 'Cambiar rol',
          icon: Icon(Icons.swap_horiz, color: Colors.grey[700]),
          onPressed: () => _changeRole(u),
        ),
        IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _delete(u),
        ),
      ],
    );
  }
}



