import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serum_business/serum_business.dart';

/// Tarjeta informativa individual para una orden en el historial del paciente.
class PatientHistoryOrderCard extends StatelessWidget {
  final OrderInDb order;
  final PatientInDb? patient;
  final bool isComparisonMode;
  final bool isSelectedForComparison;
  final ValueChanged<String> onToggleComparison;
  final VoidCallback onOpenReceipts;
  final VoidCallback onOpenInvoice;
  final VoidCallback onOpenResults;

  const PatientHistoryOrderCard({
    super.key,
    required this.order,
    this.patient,
    required this.isComparisonMode,
    required this.isSelectedForComparison,
    required this.onToggleComparison,
    required this.onOpenReceipts,
    required this.onOpenInvoice,
    required this.onOpenResults,
  });

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return 'Fecha no disponible';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy • hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.teal;
      case 'published':
        return Colors.blue;
      case 'in_process':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'pending':
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completada';
      case 'published':
        return 'Publicada';
      case 'in_process':
        return 'En Proceso';
      case 'paid':
        return 'Pagada';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final total = order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
    final pending = total - order.paidAmount;
    final isPaid = pending <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelectedForComparison ? 2 : 0,
      color: isSelectedForComparison
          ? colorScheme.primaryContainer.withAlpha(60)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelectedForComparison
              ? colorScheme.primary
              : colorScheme.outlineVariant.withAlpha(100),
          width: isSelectedForComparison ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: ID, Fecha, Badges
            Row(
              children: [
                if (isComparisonMode) ...[
                  Checkbox(
                    value: isSelectedForComparison,
                    onChanged: (_) => onToggleComparison(order.id),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${order.id}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                // Badge de estado clínico
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(order.status).withAlpha(100),
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(order.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge financiero
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green.withAlpha(30) : colorScheme.error.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPaid ? Colors.green.withAlpha(100) : colorScheme.error.withAlpha(100),
                    ),
                  ),
                  child: Text(
                    isPaid ? 'Pagada' : 'Saldo: ${NumberFormatter.convertToMoneyLike(pending)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPaid ? Colors.green.shade800 : colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de Exámenes / Ítems
            if (order.items.isNotEmpty) ...[
              Text(
                'Exámenes (${order.items.length}):',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: order.items.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isPack ? Icons.inventory_2_outlined : Icons.science_outlined,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.name,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          NumberFormatter.convertToMoneyLike(item.salePriceApplied),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 10),

            // Médico y Total
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  order.doctorInfo != null && order.doctorInfo!.name.isNotEmpty
                      ? 'Dr(a). ${order.doctorInfo!.name}'
                      : 'Sin médico asignado',
                  style: theme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'Total: ${NumberFormatter.convertToMoneyLike(total)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isComparisonMode)
                  OutlinedButton.icon(
                    onPressed: () => onToggleComparison(order.id),
                    icon: Icon(
                      isSelectedForComparison ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 16,
                    ),
                    label: Text(isSelectedForComparison ? 'Deseleccionar' : 'Seleccionar para comparar'),
                  )
                else ...[
                  TextButton.icon(
                    icon: const Icon(Icons.payments_outlined, size: 16),
                    label: const Text('Recibos'),
                    onPressed: onOpenReceipts,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.receipt_outlined, size: 16),
                    label: const Text('Factura'),
                    onPressed: onOpenInvoice,
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.assignment_outlined, size: 16),
                    label: const Text('Resultados'),
                    onPressed: onOpenResults,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
