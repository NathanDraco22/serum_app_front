import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class AddServiceDialog extends StatefulWidget {
  final OrderService? initialService;

  const AddServiceDialog({super.key, this.initialService});

  static Future<OrderService?> show(BuildContext context, {OrderService? initialService}) {
    return showDialog<OrderService>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddServiceDialog(initialService: initialService),
    );
  }

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  final FocusNode _priceFocusNode = FocusNode();

  final List<String> _quickShortcuts = const [
    'Servicio a Domicilio',
    'Toma Especial de Muestra',
    'Atención de Urgencia',
    'Transporte de Muestras',
    'Honorario Clínico Extra',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialService?.name ?? '');
    final initialPrice = widget.initialService != null
        ? NumberFormatter.convertFromCentsToDouble(widget.initialService!.price)
        : 0.0;
    _priceController = TextEditingController(
      text: initialPrice > 0 ? initialPrice.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _selectShortcut(String shortcut) {
    setState(() {
      _nameController.text = shortcut;
    });
    _priceFocusNode.requestFocus();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final rawPrice = double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0.0;
    final priceInCents = NumberFormatter.convertFromDoubleToCents(rawPrice);

    final service = OrderService(
      id: widget.initialService?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: priceInCents,
    );

    Navigator.of(context).pop(service);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialService != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.medical_services_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Servicio' : 'Agregar Servicio Adicional',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ingresa el nombre y precio del servicio libre',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Atajos rápidos
                Text(
                  'Atajos rápidos:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickShortcuts.map((shortcut) {
                    final isSelected = _nameController.text.trim() == shortcut;
                    return ActionChip(
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 14)
                          : const Icon(Icons.bolt_outlined, size: 14),
                      label: Text(shortcut, style: const TextStyle(fontSize: 12)),
                      backgroundColor: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                      onPressed: () => _selectShortcut(shortcut),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Nombre del servicio
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del servicio *',
                    hintText: 'Ej. Servicio a Domicilio',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el nombre del servicio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Precio
                TextFormField(
                  controller: _priceController,
                  focusNode: _priceFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio del servicio *',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el precio';
                    }
                    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un valor numérico válido mayor o igual a 0';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(isEditing ? 'Guardar Cambios' : 'Agregar a la Orden'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
