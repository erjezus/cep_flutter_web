import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cep_flutter_web/config/config.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/widgets/standard_card.dart';
import 'package:cep_flutter_web/widgets/responsive_container.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

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
  bool _isPaid = false;
  final baseUrl = AppConfig.baseUrl;

  final List<String> _expenseTypes = ['Común', 'Comida', 'Bebida', 'A cuenta'];
  String? _selectedExpenseType;

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
              if (!kIsWeb)
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
                title: Text(kIsWeb ? 'Seleccionar archivo' : 'Seleccionar de galería'),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final uri = Uri.parse("$baseUrl/api/expenses");
    final request = http.MultipartRequest("POST", uri)
      ..fields['user_id'] = widget.userId.toString()
      ..fields['event_id'] = widget.eventId.toString()
      ..fields['concept'] = _conceptController.text
      ..fields['amount'] = _amountController.text.replaceAll(',', '.')
      ..fields['notes'] = _notesController.text
      ..fields['expense_type'] = _selectedExpenseType!
      ..fields['paid'] = _isPaid.toString();

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
        _selectedExpenseType = null;
        _isPaid = false;
      });

      AppSnackBar.success(context, "Gasto guardado correctamente");
    } else {
      AppSnackBar.error(context, "Error al subir el gasto");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Añadir gasto"),
      ),
      body: ResponsiveContainer(
        child: Padding(
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
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tipo de gasto'),
                      items: _expenseTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      value: _selectedExpenseType,
                      onChanged: _isSubmitting ? null : (value) => setState(() => _selectedExpenseType = value),
                      validator: (value) => value == null ? 'Selecciona un tipo de gasto' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Observaciones (opcional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _isPaid,
                      onChanged: (value) => setState(() => _isPaid = value),
                      title: const Text("¿Pagado?"),
                      activeColor: mainColor,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _showImageSourceSelector,
                      icon: Icon(Icons.attach_file, size: 18, color: mainColor),
                      label: Text(
                        _selectedImage == null && _webImageBytes == null
                            ? "Adjuntar imagen (opcional)"
                            : "Imagen seleccionada ✓",
                        style: TextStyle(color: mainColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: mainColor.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_selectedImage != null || _webImageBytes != null)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 140,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        child: kIsWeb
                            ? Image.memory(_webImageBytes!, fit: BoxFit.cover, width: double.infinity)
                            : Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitExpense,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Guardar gasto"),
                      ),
                    ),
                  ],
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
