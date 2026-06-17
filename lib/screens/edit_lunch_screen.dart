import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

class EditLunchScreen extends StatefulWidget {
  final int lunchId;
  final DateTime initialDate;
  final String initialDescription;

  const EditLunchScreen({
    required this.lunchId,
    required this.initialDate,
    required this.initialDescription,
    super.key,
  });

  @override
  State<EditLunchScreen> createState() => _EditLunchScreenState();
}

class _EditLunchScreenState extends State<EditLunchScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;
  final baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final body = {
      'id': widget.lunchId.toString(),
      'date': _selectedDate.toIso8601String(),
      'description': _descriptionController.text.trim(),
    };

    final url = Uri.parse('$baseUrl/api/lunches');
    final res = await http.put(url, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
    });

    setState(() => _isSubmitting = false);

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, 'Error al actualizar almuerzo: ${res.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar almuerzo')),
      body: ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, size: 20),
                      onPressed: _pickDate,
                    ),
                  ),
                  controller: TextEditingController(
                      text: _selectedDate.toLocal().toString().split(' ')[0]),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Fecha requerida' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Actualizar almuerzo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
