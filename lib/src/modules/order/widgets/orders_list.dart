import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/order_cubit/read_orders_cubit.dart';
import '../../../cubits/order_cubit/write_orders_cubit.dart';

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
        final patientName = patientNames[order.patientId] ?? 'Cargando paciente...';
        final isCompleted = order.status == 'completed';
        final isPaid = order.status == 'paid';
        final isPartiallyPaid = order.status == 'partiallyPaid';
        final showPayButton = order.status == 'pending' || order.status == 'partiallyPaid';

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
                  backgroundColor: isCompleted ? Colors.green.shade100 : theme.colorScheme.primaryContainer,
                  foregroundColor: isCompleted ? Colors.green.shade800 : theme.colorScheme.onPrimaryContainer,
                  child: Icon(isCompleted ? Icons.check_circle : Icons.pending_actions),
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
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
                              Text('\$${order.salePriceApplied}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCompleted || isPaid
                                  ? Colors.green.shade50
                                  : isPartiallyPaid
                                      ? Colors.blue.shade50
                                      : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isCompleted || isPaid
                                    ? Colors.green.shade200
                                    : isPartiallyPaid
                                        ? Colors.blue.shade200
                                        : Colors.amber.shade200,
                              ),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCompleted || isPaid
                                    ? Colors.green.shade800
                                    : isPartiallyPaid
                                        ? Colors.blue.shade800
                                        : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => onEditResults(order),
                  icon: const Icon(Icons.assignment, size: 16),
                  label: Text(isCompleted ? 'Ver Resultados' : 'Cargar Resultados'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? theme.colorScheme.secondaryContainer : theme.colorScheme.primary,
                    foregroundColor: isCompleted ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onPrimary,
                  ),
                ),
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Orden'),
                        content: const Text('¿Está seguro de eliminar esta orden?'),
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
            ),
          ),
        );
      },
    );
  }
}
