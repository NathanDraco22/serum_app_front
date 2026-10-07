import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cubits/quotation_cubit/read_quotations_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';
import '../../../widgets/dialogs/viewers/quotation_viewer.dart';

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

    if (quotations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_outlined, size: 48, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'No se encontraron cotizaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final quotation = quotations[index];
        final totalFormatted = NumberFormatter.convertToMoneyLike(quotation.totalAmount);
        final itemsSummary = quotation.exams.map((e) => e.name).join(", ");
        final shortId = quotation.id.length > 8
            ? quotation.id.substring(quotation.id.length - 8).toUpperCase()
            : quotation.id.toUpperCase();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showQuotationViewerDialog(context, quotation),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.request_quote_outlined),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              quotation.clientName.isNotEmpty
                                  ? quotation.clientName
                                  : 'Cliente General',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#$shortId',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Análisis (${quotation.exams.length}): $itemsSummary',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(quotation.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payments,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  totalFormatted,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Acción de Ver / Imprimir
                  IconButton(
                    tooltip: 'Ver / Imprimir Cotización (PDF)',
                    icon: Icon(Icons.print_outlined, color: theme.colorScheme.primary),
                    onPressed: () => showQuotationViewerDialog(context, quotation),
                  ),
                  IconButton(
                    tooltip: 'Eliminar Cotización',
                    icon: const Icon(Icons.delete_outline),
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
          ),
        );
      },
    );
  }
}
