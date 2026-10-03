import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';
import '../../../widgets/dialogs/viewers/clinical_order_viewer.dart';

class OrdersList extends StatelessWidget {
  final List<OrderInDb> orders;
  final Function(OrderInDb) onEditResults;
  final Function(OrderInDb) onPayOrder;

  const OrdersList({
    super.key,
    required this.orders,
    required this.onEditResults,
    required this.onPayOrder,
  });

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obtener pacientes para mapear los nombres si es posible
    final patientsState = context.watch<ReadPatientCubit>().state;
    Map<String, String> patientNames = {};
    if (patientsState is ReadPatientSuccess) {
      for (var p in patientsState.items) {
        patientNames[p.id] = p.name;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final patientName =
            order.patientInfo?.name ?? patientNames[order.patientId] ?? 'Paciente';
        final totalPrice =
            order.totalPrice > 0 ? order.totalPrice : order.salePriceApplied;
        final isFullyPaid = order.status == 'paid' ||
            order.status == 'completed' ||
            (totalPrice > 0 && order.paidAmount >= totalPrice);
        final hasResults = order.results.isNotEmpty &&
            order.results.every((r) => r.resultValue != null && r.resultValue!.trim().isNotEmpty);
        final isCompleted = order.status == 'completed' || (isFullyPaid && hasResults);
        final isPartiallyPaid = order.paidAmount > 0 && !isFullyPaid;
        final showPayButton = !isFullyPaid &&
            order.status != 'completed' &&
            order.status != 'paid' &&
            order.status != 'cancelled';
        final canDelete = order.status == 'pending' && order.paidAmount == 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted
                      ? Colors.green.shade100
                      : isFullyPaid
                          ? Colors.blue.shade100
                          : hasResults
                              ? Colors.amber.shade100
                              : theme.colorScheme.primaryContainer,
                  foregroundColor: isCompleted
                      ? Colors.green.shade800
                      : isFullyPaid
                          ? Colors.blue.shade800
                          : hasResults
                              ? Colors.amber.shade900
                              : theme.colorScheme.onPrimaryContainer,
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isFullyPaid
                            ? Icons.paid
                            : hasResults
                                ? Icons.assignment_turned_in
                                : Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paciente: $patientName',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Examen: ${order.examName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(_formatDate(order.createdAt), style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(NumberFormatter.convertToMoneyLike(totalPrice), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // Badge Clínico
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasResults ? Colors.purple.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasResults ? Colors.purple.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasResults ? Icons.check_circle_outline : Icons.hourglass_top,
                                  size: 11,
                                  color: hasResults ? Colors.purple.shade800 : Colors.orange.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasResults ? 'RESULTADOS LISTOS' : 'PEND. RESULTADOS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: hasResults ? Colors.purple.shade800 : Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge Financiero
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isFullyPaid
                                  ? Colors.green.shade50
                                  : isPartiallyPaid
                                      ? Colors.blue.shade50
                                      : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isFullyPaid
                                  ? Colors.green.shade200
                                  : isPartiallyPaid
                                      ? Colors.blue.shade200
                                      : Colors.amber.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFullyPaid
                                      ? Icons.check
                                      : isPartiallyPaid
                                          ? Icons.pie_chart_outline
                                          : Icons.attach_money,
                                  size: 11,
                                  color: isFullyPaid
                                      ? Colors.green.shade800
                                      : isPartiallyPaid
                                          ? Colors.blue.shade800
                                          : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFullyPaid
                                      ? 'PAGADA'
                                      : isPartiallyPaid
                                          ? 'ABONO: ${NumberFormatter.convertToMoneyLike(order.paidAmount)} / ${NumberFormatter.convertToMoneyLike(totalPrice)}'
                                          : 'PENDIENTE DE PAGO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFullyPaid
                                        ? Colors.green.shade800
                                        : isPartiallyPaid
                                            ? Colors.blue.shade800
                                            : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isCompleted
                      ? () => showClinicalOrderViewerDialog(context, order)
                      : () => onEditResults(order),
                  icon: Icon(isCompleted ? Icons.visibility : Icons.assignment, size: 16),
                  label: Text(isCompleted ? 'Ver Resultados' : (hasResults ? 'Editar Resultados' : 'Cargar Resultados')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? theme.colorScheme.secondaryContainer
                        : (hasResults ? theme.colorScheme.tertiaryContainer : theme.colorScheme.primary),
                    foregroundColor: isCompleted
                        ? theme.colorScheme.onSecondaryContainer
                        : (hasResults ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onPrimary),
                  ),
                ),
                if (hasResults || isCompleted) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Exportar / Imprimir PDF',
                    onPressed: () => showClinicalOrderViewerDialog(context, order),
                  ),
                ],
                if (showPayButton) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => onPayOrder(order),
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Pagar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Eliminar Orden',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('Eliminar Orden'),
                          content: const Text('¿Está seguro de eliminar esta orden pendiente?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                context.read<WriteOrderCubit>().delete(order.id).then((_) {
                                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                  if (context.mounted) context.read<ReadOrderCubit>().getAll();
                                });
                              },
                              child: Text(
                                'Eliminar',
                                style: TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    color: theme.colorScheme.error,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
