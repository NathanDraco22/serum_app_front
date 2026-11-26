import 'package:material_ui/material_ui.dart';
import 'package:serum_business/serum_business.dart';

/// Diálogo para anular una orden médica solicitando el motivo obligatorio.
class CancelOrderDialog extends StatefulWidget {
  final OrderInDb order;
  final String patientName;

  const CancelOrderDialog({
    super.key,
    required this.order,
    required this.patientName,
  });

  static Future<String?> show(
    BuildContext context, {
    required OrderInDb order,
    required String patientName,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CancelOrderDialog(
        order: order,
        patientName: patientName,
      ),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
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
      setState(() => _errorText = 'El motivo de la anulación es obligatorio.');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPaidAmount = widget.order.paidAmount > 0;
    final paidFormatted =
        NumberFormatter.convertToMoneyLike(widget.order.paidAmount);

    return AlertDialog(
      icon: Icon(
        Icons.cancel_outlined,
        color: theme.colorScheme.error,
        size: 36,
      ),
      title: Text(hasPaidAmount ? 'Anular Orden y Revertir Pagos' : 'Anular Orden'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Orden #${widget.order.id} (${widget.patientName} - ${widget.order.examName})',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (hasPaidAmount) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta orden tiene $paidFormatted cobrados. Al anularla:\n'
                        '• Se anularán sus recibos activos.\n'
                        '• Se revertirá el saldo en el turno de caja abierto.\n'
                        '• Se registrará el contra-asiento en el Kardex.\n'
                        'Solo es posible si el turno original sigue abierto.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _reasonController,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: 'Motivo de la anulación *',
                hintText: 'Ej. Paciente canceló toma de muestra, error de captura...',
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
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _submit,
          icon: const Icon(Icons.delete_forever_outlined, size: 18),
          label: const Text('Anular Orden'),
        ),
      ],
    );
  }
}
