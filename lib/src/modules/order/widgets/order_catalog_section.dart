import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';
import '../../../../src/widgets/common/search_field_debounced.dart';

enum LabTestFilterType {
  all,
  individual,
  packs,
}

class OrderCatalogSection extends StatefulWidget {
  final List<LabTestInDb> allLabTests;
  final bool isLoading;
  final List<LabTestInDb> selectedItems;
  final void Function(LabTestInDb) onToggleItem;

  const OrderCatalogSection({
    super.key,
    required this.allLabTests,
    required this.isLoading,
    required this.selectedItems,
    required this.onToggleItem,
  });

  @override
  State<OrderCatalogSection> createState() => _OrderCatalogSectionState();
}

class _OrderCatalogSectionState extends State<OrderCatalogSection> {
  String _searchQuery = '';
  LabTestFilterType _selectedFilterType = LabTestFilterType.all;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter tests
    final filteredTests = widget.allLabTests.where((test) {
      // 1. Text Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = test.name.toLowerCase().contains(q);
        final matchCode = test.code != null && test.code!.toLowerCase().contains(q);
        final matchCat = test.commercialCategory.toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchCat) return false;
      }

      // 2. Type Filter
      if (_selectedFilterType == LabTestFilterType.individual && test.isPack) {
        return false;
      }
      if (_selectedFilterType == LabTestFilterType.packs && !test.isPack) {
        return false;
      }

      // 3. Category Filter
      if (_selectedCategory != null && test.commercialCategory != _selectedCategory) {
        return false;
      }

      return true;
    }).toList();

    // Available categories
    final categories = widget.allLabTests
        .map((t) => t.commercialCategory)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.biotech_outlined, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Catálogo de Pruebas y Perfiles',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredTests.length} disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SearchFieldDebounced(
                  hintText: 'Buscar análisis o perfil por nombre o código...',
                  onSearch: (q) => setState(() => _searchQuery = q.trim()),
                ),
              ],
            ),
          ),

          // Filter Chips (Type & Categories)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _selectedFilterType == LabTestFilterType.all && _selectedCategory == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilterType = LabTestFilterType.all;
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(Icons.inventory_2, size: 14, color: _selectedFilterType == LabTestFilterType.packs ? theme.colorScheme.onSecondary : theme.colorScheme.secondary),
                  label: const Text('Packs / Perfiles'),
                  selected: _selectedFilterType == LabTestFilterType.packs,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilterType = val ? LabTestFilterType.packs : LabTestFilterType.all;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(Icons.science, size: 14, color: _selectedFilterType == LabTestFilterType.individual ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
                  label: const Text('Individuales'),
                  selected: _selectedFilterType == LabTestFilterType.individual,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilterType = val ? LabTestFilterType.individual : LabTestFilterType.all;
                    });
                  },
                ),
                const VerticalDivider(width: 24, indent: 8, endIndent: 8),
                for (final cat in categories) ...[
                  ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = val ? cat : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 12),

          // Content List or Grid
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              'No se encontraron análisis que coincidan.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 500;

                          if (isWide) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 320,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 116,
                              ),
                              itemCount: filteredTests.length,
                              itemBuilder: (context, index) {
                                final test = filteredTests[index];
                                final isSelected = widget.selectedItems.any((i) => i.id == test.id);
                                return _buildTestCard(theme, test, isSelected);
                              },
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredTests.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final test = filteredTests[index];
                              final isSelected = widget.selectedItems.any((i) => i.id == test.id);
                              return _buildTestCard(theme, test, isSelected);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(ThemeData theme, LabTestInDb test, bool isSelected) {
    final priceStr = NumberFormatter.convertToMoneyLike(test.salePrice);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => widget.onToggleItem(test),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: test.isPack
                        ? theme.colorScheme.tertiaryContainer
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    test.isPack ? Icons.inventory_2 : Icons.science,
                    size: 16,
                    color: test.isPack
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        test.isPack
                            ? 'Pack (${test.childTestIds.length} análisis)'
                            : (test.commercialCategory.isNotEmpty ? test.commercialCategory : 'General'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check : Icons.add,
                        size: 14,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSelected ? 'Agregado' : 'Agregar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
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
    );
  }
}
