import 'package:flutter/material.dart';

/// Pie de acciones del diálogo de resultados (Ver Informe PDF, Cancelar/Cerrar y Guardar).
class OrderResultsFooter extends StatelessWidget {
  final bool isReadOnly;
  final bool hasResults;
  final bool isSubmitting;
  final bool canComplete;
  final VoidCallback onViewReport;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const OrderResultsFooter({
    super.key,
    this.isReadOnly = false,
    required this.hasResults,
    required this.isSubmitting,
    this.canComplete = false,
    required this.onViewReport,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isReadOnly || hasResults)
            Flexible(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Ver Informe'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: isSubmitting ? null : onViewReport,
              ),
            )
          else
            const SizedBox.shrink(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: isSubmitting ? null : onCancel,
                child: Text(isReadOnly ? 'Cerrar' : 'Cancelar'),
              ),
              if (!isReadOnly) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Guardar Resultados'),
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
