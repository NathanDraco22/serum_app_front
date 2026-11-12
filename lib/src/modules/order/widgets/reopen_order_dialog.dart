import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

/// Diálogo para reabrir una orden finalizada solicitando el motivo clínico.
class ReopenOrderDialog extends StatefulWidget {
  final OrderInDb order;

  const ReopenOrderDialog({super.key, required this.order});

  static Future<String?> show(BuildContext context, OrderInDb order) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReopenOrderDialog(order: order),
    );
  }

  @override
  State<ReopenOrderDialog> createState() => _ReopenOrderDialogState();
}

class _ReopenOrderDialogState extends State<ReopenOrderDialog> {
  final _reasonController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'El motivo de la reapertura es obligatorio.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patientName = widget.order.patientInfo?.name ?? 'Paciente';

    return AlertDialog(
      icon: Icon(Icons.history_rounded, color: Colors.amber.shade800, size: 36),
      title: const Text('Reabrir Orden Médica'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La orden #${widget.order.id} ($patientName) volverá a revisión '
              'para permitir la corrección de resultados. Los pagos y el '
              'historial de auditoría se conservan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'Motivo de la reapertura *',
                hintText: 'Ej. Corrección de valor reportado, revisión de control...',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reabrir Orden'),
        ),
      ],
    );
  }
}
