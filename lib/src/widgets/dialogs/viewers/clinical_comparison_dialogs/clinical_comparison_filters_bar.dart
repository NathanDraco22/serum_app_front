import 'package:flutter/material.dart';

/// Barra de filtros y buscador en vivo para la comparativa de exámenes.
class ClinicalComparisonFiltersBar extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final int totalRowsCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onClearSearch;

  const ClinicalComparisonFiltersBar({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.totalRowsCount,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onClearSearch,
  });

  Widget _buildFilterChip(BuildContext context, String value, String label) {
    final isSelected = selectedCategory == value;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onCategoryChanged(value);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filtrar por parámetro (ej. Hemoglobina, VCM)...',
                    hintStyle: const TextStyle(fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: onClearSearch,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 'ALL', 'Todos ($totalRowsCount)'),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'RED', 'Serie Roja'),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'WHITE', 'Serie Blanca'),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'PLATELET', 'Plaquetas'),
                  const SizedBox(width: 6),
                  _buildFilterChip(context, 'DELTA_ONLY', 'Con Variación'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
