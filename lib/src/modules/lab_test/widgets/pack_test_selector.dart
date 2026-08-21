import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class PackTestSelector extends StatefulWidget {
  final List<LabTestInDb> availableTests;
  final List<String> selectedTestIds;
  final ValueChanged<List<String>> onSelectionChanged;
  final double packSalePrice;

  const PackTestSelector({
    super.key,
    required this.availableTests,
    required this.selectedTestIds,
    required this.onSelectionChanged,
    required this.packSalePrice,
  });

  @override
  State<PackTestSelector> createState() => _PackTestSelectorState();
}

class _PackTestSelectorState extends State<PackTestSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  bool _showOnlySelected = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    final categories = <String>{'Todas'};
    for (final test in widget.availableTests) {
      if (test.commercialCategory.trim().isNotEmpty) {
        categories.add(test.commercialCategory.trim());
      }
    }
    return categories.toList();
  }

  List<LabTestInDb> _getFilteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.availableTests.where((test) {
      if (_showOnlySelected && !widget.selectedTestIds.contains(test.id)) {
        return false;
      }
      if (_selectedCategory != 'Todas' && test.commercialCategory.trim() != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = test.name.toLowerCase().contains(query);
        final matchesCode = (test.code ?? '').toLowerCase().contains(query);
        final matchesCat = test.commercialCategory.toLowerCase().contains(query);
        if (!matchesName && !matchesCode && !matchesCat) return false;
      }
      return true;
    }).toList();
  }

  void _toggleTest(String id, bool selected) {
    final updated = List<String>.from(widget.selectedTestIds);
    if (selected) {
      if (!updated.contains(id)) updated.add(id);
    } else {
      updated.remove(id);
    }
    widget.onSelectionChanged(updated);
  }

  void _selectAllFiltered(List<LabTestInDb> filtered) {
    final updated = List<String>.from(widget.selectedTestIds);
    for (final test in filtered) {
      if (!updated.contains(test.id)) {
        updated.add(test.id);
      }
    }
    widget.onSelectionChanged(updated);
  }

  void _clearSelection() {
    widget.onSelectionChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _getCategories();
    final filteredTests = _getFilteredItems();

    // Cálculos de precios acumulados
    final selectedTests = widget.availableTests
        .where((t) => widget.selectedTestIds.contains(t.id))
        .toList();
    final totalIndividualCents = selectedTests.fold<int>(0, (sum, t) => sum + t.salePrice);
    final totalIndividualPrice = totalIndividualCents / 100.0;
    final packPrice = widget.packSalePrice;
    final savings = totalIndividualPrice - packPrice;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de Búsqueda y Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Buscar análisis por nombre o clave (ej. Glucosa, GLU)...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showOnlySelected,
                      label: Text('Seleccionadas (${widget.selectedTestIds.length})'),
                      onSelected: (val) => setState(() => _showOnlySelected = val),
                      avatar: Icon(
                        _showOnlySelected ? Icons.check_circle : Icons.check_circle_outline,
                        size: 16,
                        color: _showOnlySelected ? theme.colorScheme.onSecondaryContainer : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Chips de Categorías
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Acciones de Selección Rápida
          Container(
            color: theme.colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  'Mostrando ${filteredTests.length} de ${widget.availableTests.length} pruebas',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                if (filteredTests.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () => _selectAllFiltered(filteredTests),
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Seleccionar visibles', style: TextStyle(fontSize: 12)),
                  ),
                if (widget.selectedTestIds.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Deseleccionar todo', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lista de Pruebas con Scroll Virtualizado
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, minHeight: 120),
            child: filteredTests.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 36, color: theme.colorScheme.outline),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron análisis que coincidan.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTests.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 48,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final test = filteredTests[index];
                      final isSelected = widget.selectedTestIds.contains(test.id);
                      final testPrice = (test.salePrice / 100.0).toStringAsFixed(2);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) => _toggleTest(test.id, val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: theme.colorScheme.primary,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                test.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (test.code != null && test.code!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  test.code!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Text(
                              '\$$testPrice USD',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Text(
                                test.commercialCategory.isNotEmpty
                                    ? test.commercialCategory
                                    : 'Sin Categoría',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (test.unitOfMeasure.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  test.unitOfMeasure,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),

          // Resumen de Precios y Ahorro en tiempo real
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.selectedTestIds.length} análisis incluidos en el pack',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Suma de precios individuales: \$${totalIndividualPrice.toStringAsFixed(2)} USD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.selectedTestIds.isNotEmpty && packPrice > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: savings > 0
                          ? Colors.green.shade50
                          : theme.colorScheme.surfaceContainerLowest,
                      border: Border.all(
                        color: savings > 0 ? Colors.green.shade400 : theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          savings > 0
                              ? 'Ahorro al cliente: \$${savings.toStringAsFixed(2)} USD'
                              : 'Precio del Pack: \$${packPrice.toStringAsFixed(2)} USD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: savings > 0 ? Colors.green.shade800 : theme.colorScheme.primary,
                          ),
                        ),
                        if (savings > 0 && totalIndividualPrice > 0)
                          Text(
                            '(${((savings / totalIndividualPrice) * 100).toStringAsFixed(1)}% descuento)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
