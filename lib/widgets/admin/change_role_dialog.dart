import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/models/user.dart';
import 'package:cep_flutter_web/services/user_management_service.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

/// Diálogo para cambiar únicamente el rol de un usuario (solo ADMIN).
class ChangeRoleDialog extends StatefulWidget {
  final UserManagementService service;
  final User user;

  const ChangeRoleDialog({required this.service, required this.user, super.key});

  static Future<bool> show(
    BuildContext context,
    UserManagementService service,
    User user,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeRoleDialog(service: service, user: user),
    );
    return result ?? false;
  }

  @override
  State<ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<ChangeRoleDialog> {
  late String _newRole;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _newRole = widget.user.role;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.service.changeUserRole(widget.user.id, _newRole);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final willBeAdmin = _newRole == 'ADMIN';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cambiar rol', style: TextStyle(fontWeight: FontWeight.bold)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: ${widget.user.username}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Rol actual: ${widget.user.role}',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _newRole,
              decoration: const InputDecoration(
                labelText: 'Nuevo rol',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: const [
                DropdownMenuItem(value: 'USER', child: Text('USER')),
                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _newRole = v ?? 'USER'),
            ),
            if (willBeAdmin && widget.user.role != 'ADMIN') ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cambiar a ADMIN otorgará acceso administrativo.',
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton.icon(
          onPressed:
              (_submitting || _newRole == widget.user.role) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.2),
                )
              : const Icon(Icons.check),
          label: Text(_submitting ? 'Cambiando...' : 'Cambiar rol'),
        ),
      ],
    );
  }
}

