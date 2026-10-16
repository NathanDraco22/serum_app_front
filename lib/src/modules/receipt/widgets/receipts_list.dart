import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import 'receipt_detail_dialog.dart';
import '../../../widgets/dialogs/viewers/receipt_viewer.dart';

class ReceiptsList extends StatelessWidget {
  final List<ReceiptInDb> receipts;

  const ReceiptsList({
    super.key,
    required this.receipts,
  });

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Colors.blue;
      case 'transfer':
        return Colors.purple;
      case 'cash':
      default:
        return Colors.green;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'transfer':
        return Icons.account_balance;
      case 'cash':
      default:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (receipts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No se encontraron recibos de caja',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Los recibos se generan automáticamente al registrar abonos o pagos en las órdenes.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        final methodColor = _getPaymentMethodColor(receipt.paymentMethod);
        final methodIcon = _getPaymentMethodIcon(receipt.paymentMethod);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: () => ReceiptDetailDialog.show(context, receipt),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono / Badge del método
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: methodColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(methodIcon, color: methodColor, size: 24),
                  ),
                  const SizedBox(width: 16),

                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Recibo #${receipt.receiptNumber}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: methodColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                receipt.paymentMethodLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: methodColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Orden #${receipt.orderId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              receipt.patientName ?? 'Público General',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cajero: ${receipt.performedBy.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              receipt.formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            if (receipt.shiftId != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                '•  Turno #${receipt.shiftId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                receipt.concept,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Monto y acción
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        receipt.formattedAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () =>
                            ReceiptDetailDialog.show(context, receipt),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                        label: const Text('Ver Detalle', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Ver / Imprimir Recibo (PDF)',
                    icon: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.primary),
                    onPressed: () => showReceiptViewerDialog(context, receipt),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
