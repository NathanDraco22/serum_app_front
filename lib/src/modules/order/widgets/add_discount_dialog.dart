import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class AddDiscountDialog extends StatefulWidget {
  final int currentSubtotal;
  final OrderDiscount? initialDiscount;

  const AddDiscountDialog({
    super.key,
    required this.currentSubtotal,
    this.initialDiscount,
  });

  static Future<OrderDiscount?> show(
    BuildContext context, {
    required int currentSubtotal,
    OrderDiscount? initialDiscount,
  }) {
    return showDialog<OrderDiscount>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddDiscountDialog(
        currentSubtotal: currentSubtotal,
        initialDiscount: initialDiscount,
      ),
    );
  }

  @override
  State<AddDiscountDialog> createState() => _AddDiscountDialogState();
}

class _AddDiscountDialogState extends State<AddDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  final FocusNode _valueFocusNode = FocusNode();

  String _discountType = 'percentage'; // 'percentage' | 'amount'

  final List<Map<String, dynamic>> _percentageShortcuts = const [
    {'label': 'Tercera Edad (15%)', 'desc': 'Descuento Tercera Edad', 'val': 15.0},
    {'label': 'Convenio Inst. (10%)', 'desc': 'Convenio Institucional', 'val': 10.0},
    {'label': 'Promoción (20%)', 'desc': 'Promoción Especial', 'val': 20.0},
    {'label': 'Cortesía Médica (100%)', 'desc': 'Cortesía Médica', 'val': 100.0},
    {'label': 'Ajuste Comercial (5%)', 'desc': 'Ajuste Comercial', 'val': 5.0},
  ];

  final List<Map<String, dynamic>> _amountShortcuts = const [
    {'label': 'C\$ 50.00', 'desc': 'Descuento C\$ 50.00', 'val': 50.0},
    {'label': 'C\$ 100.00', 'desc': 'Descuento C\$ 100.00', 'val': 100.0},
    {'label': 'C\$ 200.00', 'desc': 'Descuento C\$ 200.00', 'val': 200.0},
    {'label': 'Ajuste de Saldo', 'desc': 'Ajuste de Saldo Comercial', 'val': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    _discountType = widget.initialDiscount?.type ?? 'percentage';
    _descriptionController =
        TextEditingController(text: widget.initialDiscount?.description ?? '');

    double initialVal = 0.0;
    if (widget.initialDiscount != null) {
      if (widget.initialDiscount!.isPercentage) {
        initialVal = widget.initialDiscount!.value;
      } else {
        initialVal = NumberFormatter.convertFromCentsToDouble(
            widget.initialDiscount!.appliedAmount > 0
                ? widget.initialDiscount!.appliedAmount
                : widget.initialDiscount!.value.toInt());
      }
    }

    _valueController = TextEditingController(
      text: initialVal > 0 ? (initialVal % 1 == 0 ? initialVal.toInt().toString() : initialVal.toStringAsFixed(2)) : '',
    );

    _valueController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  void _selectShortcut(Map<String, dynamic> item) {
    setState(() {
      _descriptionController.text = item['desc'] as String;
      final val = item['val'] as double;
      if (val > 0) {
        _valueController.text = val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
      }
    });
    _valueFocusNode.requestFocus();
  }

  int _calculateDeductionCents() {
    final rawVal = double.tryParse(_valueController.text.trim().replaceAll(',', '')) ?? 0.0;
    if (rawVal <= 0) return 0;

    if (_discountType == 'percentage') {
      final deduction = (widget.currentSubtotal * rawVal) / 100.0;
      return deduction.round().clamp(0, widget.currentSubtotal);
    } else {
      final deduction = NumberFormatter.convertFromDoubleToCents(rawVal);
      return deduction.clamp(0, widget.currentSubtotal);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final rawVal = double.tryParse(_valueController.text.trim().replaceAll(',', '')) ?? 0.0;
    final deductionCents = _calculateDeductionCents();

    final discount = OrderDiscount(
      id: widget.initialDiscount?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      type: _discountType,
      value: rawVal,
      appliedAmount: deductionCents,
    );

    Navigator.of(context).pop(discount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialDiscount != null;
    final deductionCents = _calculateDeductionCents();
    final newEstimatedTotal = (widget.currentSubtotal - deductionCents).clamp(0, widget.currentSubtotal);

    final shortcuts = _discountType == 'percentage' ? _percentageShortcuts : _amountShortcuts;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.discount_outlined,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Descuento' : 'Agregar Descuento a la Orden',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Aplica una deducción por porcentaje o monto fijo',
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

                // Selector de Modalidad (Porcentaje vs Monto Fijo)
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'percentage',
                        label: Text('Porcentaje (%)'),
                        icon: Icon(Icons.percent, size: 16),
                      ),
                      ButtonSegment(
                        value: 'amount',
                        label: Text('Monto Fijo (C\$)'),
                        icon: Icon(Icons.attach_money, size: 16),
                      ),
                    ],
                    selected: {_discountType},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _discountType = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),

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
                  children: shortcuts.map((item) {
                    final isSelected = _descriptionController.text.trim() == item['desc'];
                    return ActionChip(
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 14)
                          : const Icon(Icons.bolt_outlined, size: 14),
                      label: Text(item['label'] as String, style: const TextStyle(fontSize: 12)),
                      backgroundColor: isSelected
                          ? theme.colorScheme.tertiaryContainer
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onTertiaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.outlineVariant,
                      ),
                      onPressed: () => _selectShortcut(item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Motivo / Concepto del descuento
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo o Concepto del Descuento *',
                    hintText: 'Ej. Tercera Edad, Convenio, Promoción',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa el motivo del descuento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Valor del descuento
                TextFormField(
                  controller: _valueController,
                  focusNode: _valueFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _discountType == 'percentage'
                        ? 'Porcentaje de descuento (%) *'
                        : 'Monto de descuento (C\$) *',
                    hintText: _discountType == 'percentage' ? 'Ej. 15' : 'Ej. 100.00',
                    prefixIcon: Icon(_discountType == 'percentage' ? Icons.percent : Icons.attach_money),
                    suffixText: _discountType == 'percentage' ? '%' : 'C\$',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el valor del descuento';
                    }
                    final parsed = double.tryParse(value.trim().replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un valor numérico válido mayor a 0';
                    }
                    if (_discountType == 'percentage' && parsed > 100) {
                      return 'El porcentaje no puede ser superior al 100%';
                    }
                    if (_discountType == 'amount') {
                      final inCents = NumberFormatter.convertFromDoubleToCents(parsed);
                      if (inCents > widget.currentSubtotal) {
                        return 'El monto no puede superar el subtotal (${NumberFormatter.convertToMoneyLike(widget.currentSubtotal)})';
                      }
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 14),

                // Cuadro dinámico de previsualización
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Subtotal actual:', style: theme.textTheme.bodySmall),
                          ),
                          Text(NumberFormatter.convertToMoneyLike(widget.currentSubtotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Deducción a aplicar:',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade700)),
                          ),
                          Text(
                            '- ${NumberFormatter.convertToMoneyLike(deductionCents)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Total resultante estimado:',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            NumberFormatter.convertToMoneyLike(newEstimatedTotal),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      label: Text(isEditing ? 'Guardar Cambios' : 'Aplicar Descuento'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
