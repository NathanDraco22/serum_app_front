import 'package:flutter/material.dart';

/// Estado vacío para el historial de órdenes de un paciente.
class PatientHistoryEmptyState extends StatelessWidget {
  final bool hasFiltersApplied;
  final VoidCallback onClearFilters;

  const PatientHistoryEmptyState({
    super.key,
    required this.hasFiltersApplied,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.outline.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              hasFiltersApplied
                  ? 'No se encontraron órdenes con los filtros aplicados'
                  : 'Este paciente aún no tiene órdenes registradas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFiltersApplied) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Limpiar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
