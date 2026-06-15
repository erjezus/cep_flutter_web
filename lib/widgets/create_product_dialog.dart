import 'package:flutter/material.dart';
import 'package:cep_flutter_web/config/app_colors.dart';
import 'package:cep_flutter_web/services/product_service.dart';
import 'package:cep_flutter_web/widgets/app_snackbar.dart';

/// Diálogo/formulario reutilizable para crear un producto nuevo con un
/// precio personalizado para un evento.
///
/// Se muestra con [CreateProductDialog.show], que devuelve `true` si el
/// producto se creó correctamente (para que la pantalla recargue la lista).
class CreateProductDialog extends StatefulWidget {
  final int eventId;

  const CreateProductDialog({required this.eventId, super.key});

  /// Abre el diálogo y devuelve `true` si se creó un producto.
  static Future<bool> show(BuildContext context, int eventId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateProductDialog(eventId: eventId),
    );
    return result ?? false;
  }

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _customPriceController = TextEditingController();

  static const List<String> _typologies = ['Bebida', 'Comida', 'Otro'];
  String? _selectedTypology;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _unitPriceController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduce un precio';
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Debe ser un número válido';
    }
    if (parsed < 0) {
      return 'Debe ser mayor o igual a 0';
    }
    return null;
  }

  double _parsePrice(TextEditingController c) =>
      double.parse(c.text.replaceAll(',', '.'));

  Future<void> _submit() async {
    // Cerramos el teclado y validamos.
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypology == null) return;

    setState(() => _isSubmitting = true);

    try {
      await ProductService.createProductWithEventPrice(
        name: _nameController.text.trim(),
        typology: _selectedTypology!,
        unitPrice: _parsePrice(_unitPriceController),
        eventId: widget.eventId,
        customPrice: _parsePrice(_customPriceController),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      AppSnackBar.success(context, 'Producto creado correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      AppSnackBar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Nuevo producto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        // Ancho cómodo y responsive en web/escritorio.
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedTypology,
                  decoration: const InputDecoration(
                    labelText: 'Tipología',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _typologies
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedTypology = value),
                  validator: (v) =>
                      v == null ? 'Selecciona una tipología' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _unitPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Precio unitario (€)',
                    prefixIcon: Icon(Icons.euro_outlined),
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _customPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Precio para el evento (€)',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: _validatePrice,
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isSubmitting ? 'Creando...' : 'Crear'),
        ),
      ],
    );
  }
}

