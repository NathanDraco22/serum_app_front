import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../widgets/dialogs/viewers/receipt_viewer.dart';

class ReceiptDetailDialog extends StatelessWidget {
  final ReceiptInDb receipt;

  const ReceiptDetailDialog({super.key, required this.receipt});

  static Future<void> show(BuildContext context, ReceiptInDb receipt) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReceiptDetailDialog(receipt: receipt),
    );
  }

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
    final sessionBranch = context.watch<AppSessionCubit>().state.currentBranch;
    final methodColor = _getPaymentMethodColor(receipt.paymentMethod);
    final methodIcon = _getPaymentMethodIcon(receipt.paymentMethod);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header del comprobante
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECIBO DE CAJA',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Folio: #${receipt.receiptNumber}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Ver Comprobante PDF',
                    onPressed: () => showReceiptViewerDialog(context, receipt),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Membrete de Laboratorio
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionBranch?.name ?? 'Laboratorio Clínico Serum',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (sessionBranch?.address != null && sessionBranch!.address.isNotEmpty)
                      Text(
                        sessionBranch.address,
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (sessionBranch?.phone != null && sessionBranch!.phone.isNotEmpty)
                      Text(
                        'Tel: ${sessionBranch.phone}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Monto destacado
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    Text(
                      'MONTO RECIBIDO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.formattedAmount,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: methodColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: methodColor.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(methodIcon, size: 14, color: methodColor),
                          const SizedBox(width: 6),
                          Text(
                            receipt.paymentMethodLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: methodColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Datos Detallados
              _buildDetailRow(
                context,
                icon: Icons.person_outline,
                label: 'Paciente:',
                value: receipt.patientName ?? 'Público General',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.assignment_outlined,
                label: 'Orden Relacionada:',
                value: 'Orden #${receipt.orderId}',
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.info_outline,
                label: 'Concepto:',
                value: receipt.concept,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.calendar_today_outlined,
                label: 'Fecha y Hora:',
                value: receipt.formattedDate,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.badge_outlined,
                label: 'Cajero / Operador:',
                value: receipt.performedBy.name,
              ),
              if (receipt.shiftId != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  icon: Icons.lock_clock_outlined,
                  label: 'Turno de Caja:',
                  value: 'Turno #${receipt.shiftId}',
                ),
              ],

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Ver / Imprimir PDF'),
                    onPressed: () => showReceiptViewerDialog(context, receipt),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
