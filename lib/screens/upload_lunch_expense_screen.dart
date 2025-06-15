import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';

class UploadLunchExpenseScreen extends StatefulWidget {
  final int userId;
  final int eventId;
  final int lunchId;

  const UploadLunchExpenseScreen({
    required this.userId,
    required this.eventId,
    required this.lunchId,
    super.key,
  });

  @override
  State<UploadLunchExpenseScreen> createState() => _UploadLunchExpenseScreenState();
}

class _UploadLunchExpenseScreenState extends State<UploadLunchExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  File? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isSubmitting = false;
  final baseUrl = AppConfig.baseUrl;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);

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

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint("⚠️ Formulario no válido");
      return;
    }

    setState(() => _isSubmitting = true);
    debugPrint("📤 Enviando gasto a $baseUrl/api/expenses");

    final uri = Uri.parse("$baseUrl/api/expenses");
    final request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = widget.userId.toString()
      ..fields['event_id'] = widget.eventId.toString()
      ..fields['concept'] = _conceptController.text
      ..fields['amount'] = _amountController.text
      ..fields['notes'] = _notesController.text
      ..fields['expense_type'] = 'Almuerzo';

    if (kIsWeb && _webImageBytes != null) {
      debugPrint("🖼️ Añadiendo imagen desde Web");
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _webImageBytes!,
        filename: 'upload.png',
        contentType: MediaType('image', 'png'),
      ));
    } else if (_selectedImage != null) {
      debugPrint("🖼️ Añadiendo imagen desde dispositivo");
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
    }

    final res = await request.send();
    debugPrint("📬 Respuesta al crear gasto: ${res.statusCode}");

    if (res.statusCode == 200) {
      final responseBody = await http.Response.fromStream(res);
      final decoded = jsonDecode(responseBody.body);
      final expenseId = decoded['id'];
      debugPrint("🆔 ID del gasto creado: $expenseId");

      if (expenseId != null) {
        final payload = {
          "expense_id": expenseId,
          "lunch_id": widget.lunchId,
          "user_id": widget.userId,
        };

        debugPrint("🔗 Enviando asociación a /api/expense_lunch con payload: $payload");

        final linkRes = await http.post(
          Uri.parse("$baseUrl/api/expense_lunch"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        debugPrint("📬 Respuesta al enlazar gasto: ${linkRes.statusCode} - ${linkRes.body}");

        if (linkRes.statusCode == 201 || linkRes.statusCode == 200) {
          debugPrint("✅ Gasto enlazado al almuerzo correctamente");
        } else {
          debugPrint("❌ Error al enlazar gasto: ${linkRes.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al enlazar gasto con almuerzo")),
          );
        }
      } else {
        debugPrint("❌ No se pudo obtener el ID del gasto");
      }

      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _isSubmitting = false);
      debugPrint("❌ Error al subir gasto: código ${res.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al subir el gasto"), backgroundColor: Colors.red),
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
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _showImageSourceSelector,
                      icon: Icon(Icons.attach_file, color: mainColor),
                      label: Text("Seleccionar imagen (opcional)", style: TextStyle(color: mainColor)),
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