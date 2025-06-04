import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar almuerzo: ${res.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFF388E3C);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Almuerzo'), backgroundColor: mainColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
                controller: TextEditingController(text: _selectedDate.toLocal().toString().split(' ')[0]),
                validator: (v) => v == null || v.isEmpty ? 'Fecha requerida' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: mainColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Actualizar Almuerzo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
