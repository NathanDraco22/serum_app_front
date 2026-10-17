import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serum_business/serum_business.dart';

class EditItemPriceDialog extends StatefulWidget {
  final String testName;
  final int catalogPrice;
  final int currentPrice;

  const EditItemPriceDialog({
    super.key,
    required this.testName,
    required this.catalogPrice,
    required this.currentPrice,
  });

  static Future<int?> show(
    BuildContext context, {
    required String testName,
    required int catalogPrice,
    required int currentPrice,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditItemPriceDialog(
        testName: testName,
        catalogPrice: catalogPrice,
        currentPrice: currentPrice,
      ),
    );
  }

  @override
  State<EditItemPriceDialog> createState() => _EditItemPriceDialogState();
}

class _EditItemPriceDialogState extends State<EditItemPriceDialog> {
  late final TextEditingController _controller;
  bool _isDifferent = false;

  @override
  void initState() {
    super.initState();
    final double inUnits = widget.currentPrice / 100.0;
    _controller = TextEditingController(
      text: inUnits.toStringAsFixed(2),
    );
    _checkDifference();
    _controller.addListener(_checkDifference);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkDifference() {
    final parsed = _parseCents();
    final diff = parsed != widget.catalogPrice;
    if (diff != _isDifferent) {
      setState(() {
        _isDifferent = diff;
      });
    }
  }

  int _parseCents() {
    final text = _controller.text.trim().replaceAll(',', '.');
    final val = double.tryParse(text) ?? 0.0;
    return (val * 100).round();
  }

  void _resetToCatalog() {
    final double inUnits = widget.catalogPrice / 100.0;
    _controller.text = inUnits.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogStr = NumberFormatter.convertToMoneyLike(widget.catalogPrice);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit_note_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modificar Precio de Análisis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.testName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Precio de Catálogo (Precio 1): ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  catalogStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nuevo Precio Aplicado (\$)',
                hintText: '0.00',
                prefixText: '\$ ',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Restablecer a precio de catálogo',
                  onPressed: _resetToCatalog,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_isDifferent)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El precio ingresado es diferente al catálogo. La orden requerirá autorización de un supervisor (nivel > 3) para cobrar o registrar resultados clínicos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade800,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Precio estándar de catálogo. No requiere autorización.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final parsedCents = _parseCents();
            Navigator.pop(context, parsedCents);
          },
          child: const Text('Aplicar Precio'),
        ),
      ],
    );
  }
}
