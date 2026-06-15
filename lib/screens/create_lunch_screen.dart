import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

class CreateLunchScreen extends StatefulWidget {
  final int eventId;

  const CreateLunchScreen({required this.eventId, super.key});

  @override
  State<CreateLunchScreen> createState() => _CreateLunchScreenState();
}

class _CreateLunchScreenState extends State<CreateLunchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final baseUrl = AppConfig.baseUrl;
  final mainColor = AppColors.primary;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final body = {
      'event_id': widget.eventId,
      'description': _descriptionController.text.trim(),
    };

    final url = Uri.parse('$baseUrl/api/lunches');
    final res = await http.post(url, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
    });

    setState(() => _isSubmitting = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, 'Error al crear almuerzo: ${res.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Almuerzo'),
      ),
      body: ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Este campo es obligatorio' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text("Crear Almuerzo"),
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
