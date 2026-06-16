import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/services/event_management_service.dart';

/// Diálogo para crear o editar un evento (solo admin).
///
/// Si [event] es `null` funciona en modo creación; si se pasa un mapa de
/// evento, funciona en modo edición con los datos precargados.
class EventFormDialog extends StatefulWidget {
  final EventManagementService service;
  final Map<String, dynamic>? event;

  const EventFormDialog({required this.service, this.event, super.key});

  /// Muestra el diálogo y devuelve `true` si se creó/actualizó correctamente.
  static Future<bool> show(
    BuildContext context,
    EventManagementService service, {
    Map<String, dynamic>? event,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EventFormDialog(service: service, event: event),
    );
    return result ?? false;
  }

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _status;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.event?['name']?.toString() ?? '');
    _status = (widget.event?['status']?.toString().toLowerCase() ?? 'active');
    if (_status != 'active' && _status != 'inactive') _status = 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? get _createdAtLabel {
    final raw = widget.event?['created_at'];
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return raw.toString();
    return parsed.toLocal().toString().split(' ')[0];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await widget.service.updateEvent(
          id: widget.event!['id'] as int,
          name: _nameController.text.trim(),
          status: _status,
        );
      } else {
        await widget.service.createEvent(
          name: _nameController.text.trim(),
          status: _status,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = _createdAtLabel;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEdit ? 'Editar evento' : 'Nuevo evento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Activo')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
            if (_isEdit && createdAt != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Creado el $createdAt',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: AppColors.negative, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(_isEdit ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}

