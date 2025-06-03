import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class UploadExpenseScreen extends StatefulWidget {
  final int userId;
  final int eventId;

  const UploadExpenseScreen({
    required this.userId,
    required this.eventId,
    super.key,
  });

  @override
  State<UploadExpenseScreen> createState() => _UploadExpenseScreenState();
}

class _UploadExpenseScreenState extends State<UploadExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;
  bool _isShared = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final uri = Uri.parse("http://localhost:8080/api/expenses");
    final request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = widget.userId.toString()
      ..fields['event_id'] = widget.eventId.toString()
      ..fields['concept'] = _conceptController.text
      ..fields['amount'] = _amountController.text
      ..fields['notes'] = _notesController.text
      ..fields['is_shared'] = _isShared.toString();

    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );
    }

    final res = await request.send();

    setState(() => _isSubmitting = false);

    if (res.statusCode == 200) {
      _formKey.currentState!.reset();
      _conceptController.clear();
      _amountController.clear();
      _notesController.clear();
      setState(() {
        _selectedImage = null;
        _isShared = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gasto guardado correctamente"),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error al subir el gasto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = Color(0xFFD32F2F);

    return Scaffold(
      appBar: AppBar(
        title: Text("Nuevo gasto"),
        backgroundColor: mainColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _conceptController,
                decoration: InputDecoration(labelText: 'Concepto'),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Cantidad (€)'),
                validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Observaciones (opcional)'),
                maxLines: 3,
              ),
              CheckboxListTile(
                title: Text("¿Gasto común?"),
                value: _isShared,
                onChanged: _isSubmitting ? null : (v) => setState(() => _isShared = v!),
                activeColor: mainColor,
              ),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _pickImage,
                icon: Icon(Icons.attach_file, color: mainColor),
                label: Text(
                  "Seleccionar imagen (opcional)",
                  style: TextStyle(color: mainColor),
                ),
              ),
              if (_selectedImage != null)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  height: 150,
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text("Guardar gasto"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
