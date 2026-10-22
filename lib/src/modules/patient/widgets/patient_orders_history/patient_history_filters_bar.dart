import 'package:flutter/material.dart';

/// Barra de búsqueda y chips de filtro por estado clínico en el historial de órdenes.
class PatientHistoryFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final VoidCallback onClearSearch;

  const PatientHistoryFiltersBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onClearSearch,
  });

  Widget _buildStatusChip(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    final isSelected = selectedStatus == value;

    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onStatusFilterChanged(value);
        }
      },
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Buscador
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por orden, examen o médico...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: onClearSearch,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Chips de filtro por estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(context, 'ALL', 'Todas'),
                const SizedBox(width: 6),
                _buildStatusChip(context, 'completed', 'Completadas'),
                const SizedBox(width: 6),
                _buildStatusChip(context, 'in_process', 'En Proceso'),
                const SizedBox(width: 6),
                _buildStatusChip(context, 'pending', 'Pendientes'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
