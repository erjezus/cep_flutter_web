import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // <-- necesario para MediaType
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

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
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;
  bool _isShared = false;
  final baseUrl = AppConfig.baseUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _selectedImage = null;
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final uri = Uri.parse("$baseUrl/api/expenses");
    final request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = widget.userId.toString()
      ..fields['event_id'] = widget.eventId.toString()
      ..fields['concept'] = _conceptController.text
      ..fields['amount'] = _amountController.text
      ..fields['notes'] = _notesController.text
      ..fields['is_shared'] = _isShared.toString();

    if (kIsWeb && _webImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _webImageBytes!,
        filename: 'upload.png',
        contentType: MediaType('image', 'png'),
      ));
    } else if (_selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
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
        _webImageBytes = null;
        _isShared = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gasto guardado correctamente"),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error al subir el gasto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = const Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nuevo gasto", style: TextStyle(color: Colors.white)),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              StandardCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _conceptController,
                      decoration: const InputDecoration(labelText: 'Concepto'),
                      validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Cantidad (€)'),
                      validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
                      maxLines: 3,
                    ),
                    CheckboxListTile(
                      title: const Text("¿Gasto común?"),
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
                    if (_selectedImage != null || _webImageBytes != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 150,
                        child: kIsWeb
                            ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                            : Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : const Text("Guardar gasto"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
