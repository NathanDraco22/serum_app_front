import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/quotation_cubit/read_quotations_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';

class QuotationsList extends StatelessWidget {
  final List<QuotationInDb> quotations;

  const QuotationsList({super.key, required this.quotations});

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final quotation = quotations[index];
        final isConverted = quotation.status == 'converted';

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
                  backgroundColor: isConverted ? Colors.green.shade100 : theme.colorScheme.secondaryContainer,
                  foregroundColor: isConverted ? Colors.green.shade800 : theme.colorScheme.onSecondaryContainer,
                  child: Icon(isConverted ? Icons.check_circle : Icons.description),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cliente/Paciente: ${quotation.clientName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exámenes: ${quotation.exams.map((e) => e.examName).join(", ")}',
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
                              Text(_formatDate(quotation.createdAt), style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments, size: 12, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('\$${quotation.totalAmount}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConverted ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isConverted ? Colors.green.shade200 : Colors.amber.shade200),
                            ),
                            child: Text(
                              quotation.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isConverted ? Colors.green.shade800 : Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isConverted) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      final update = UpdateQuotation(status: 'converted');
                      context.read<WriteQuotationCubit>().update(quotation.id, update).then((_) {
                        if (context.mounted) context.read<ReadQuotationCubit>().getAll();
                      });
                    },
                    icon: const Icon(Icons.sync_alt, size: 16),
                    label: const Text('Convertir a Orden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Eliminar Cotización'),
                        content: const Text('¿Está seguro de eliminar esta cotización?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<WriteQuotationCubit>().delete(quotation.id).then((_) {
                                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                                if (context.mounted) context.read<ReadQuotationCubit>().getAll();
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
