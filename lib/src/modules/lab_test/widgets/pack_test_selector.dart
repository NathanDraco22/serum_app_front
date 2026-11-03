import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

class PackTestSelector extends StatefulWidget {
  final List<LabTestInDb> availableTests;
  final List<String> selectedTestIds;
  final ValueChanged<List<String>> onSelectionChanged;
  final double packSalePrice;
  final bool useChildTestsPriceSum;
  final void Function(LabTestInDb test)? onEditTest;

  const PackTestSelector({
    super.key,
    required this.availableTests,
    required this.selectedTestIds,
    required this.onSelectionChanged,
    required this.packSalePrice,
    this.useChildTestsPriceSum = true,
    this.onEditTest,
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
    final sorted = categories.toList();
    sorted.sort((a, b) {
      if (a == 'Todas') return -1;
      if (b == 'Todas') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }

  List<LabTestInDb> _getFilteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    final items = widget.availableTests.where((test) {
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
        final matchesSub = test.subclassification.toLowerCase().contains(query);
        if (!matchesName && !matchesCode && !matchesCat && !matchesSub) return false;
      }
      return true;
    }).toList();

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
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

  void _onReorderItem(int oldIndex, int newIndex) {
    final updated = List<String>.from(widget.selectedTestIds);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    widget.onSelectionChanged(updated);
  }

  void _moveItem(int currentIndex, int targetIndex) {
    if (currentIndex < 0 || currentIndex >= widget.selectedTestIds.length) return;
    if (targetIndex < 0 || targetIndex >= widget.selectedTestIds.length) return;
    final updated = List<String>.from(widget.selectedTestIds);
    final item = updated.removeAt(currentIndex);
    updated.insert(targetIndex, item);
    widget.onSelectionChanged(updated);
  }

  String _formatReferenceSummary(LabTestInDb test) {
    if (test.dataType == 'numeric') {
      final unit = test.unitOfMeasure.isNotEmpty ? ' ${test.unitOfMeasure}' : '';
      if (test.referenceValues.isNotEmpty) {
        final ref = test.referenceValues.first;
        final minStr =
            ref.minValue % 1 == 0 ? ref.minValue.toInt().toString() : ref.minValue.toString();
        final maxStr =
            ref.maxValue % 1 == 0 ? ref.maxValue.toInt().toString() : ref.maxValue.toString();
        return 'Ref: $minStr - $maxStr$unit';
      }
      return 'Numérico${unit.isNotEmpty ? ' ($unit)' : ''}';
    } else if (test.dataType == 'qualitative') {
      final exp = test.expectedQualitativeValue;
      if (exp != null && exp.isNotEmpty) {
        return 'Cualitativo [Esperado: $exp]';
      }
      if (test.qualitativeOptions.isNotEmpty) {
        return 'Cualitativo [${test.qualitativeOptions.take(3).join(', ')}${test.qualitativeOptions.length > 3 ? '...' : ''}]';
      }
      return 'Cualitativo';
    } else {
      if (test.referenceText.isNotEmpty) {
        final preview = test.referenceText.length > 35
            ? '${test.referenceText.substring(0, 35)}...'
            : test.referenceText;
        return 'Texto: $preview';
      }
      return 'Texto Libre';
    }
  }

  Widget _buildSelectedTestsSection(
    BuildContext context,
    ThemeData theme,
    List<LabTestInDb> selectedTests,
  ) {
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add_check_circle_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parámetros y Análisis en este Perfil',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedTests.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (selectedTests.length > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(Arrastra o usa ▲▼ para ordenar)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                if (selectedTests.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Quitar todos', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ),
          if (selectedTests.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aún no hay análisis o parámetros asignados a este perfil. Búscalos en el catálogo inferior o haz clic en "Crear Parámetro en este Perfil".',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250, minHeight: 60),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: selectedTests.length,
                onReorderItem: _onReorderItem,
                itemBuilder: (context, index) {
                  final test = selectedTests[index];
                  final refSummary = _formatReferenceSummary(test);
                  final isFirst = index == 0;
                  final isLast = index == selectedTests.length - 1;

                  return Container(
                    key: ValueKey(test.id),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            // 1. Handle de Arrastre para Reordenar
                            ReorderableDragStartListener(
                              index: index,
                              child: Tooltip(
                                message: 'Arrastre para reordenar',
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.grab,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      Icons.drag_indicator_rounded,
                                      size: 20,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Botones de Subir y Bajar
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: isFirst ? null : () => _moveItem(index, index - 1),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Tooltip(
                                    message: 'Mover arriba',
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.arrow_drop_up_rounded,
                                        size: 18,
                                        color: isFirst
                                            ? theme.colorScheme.outline.withValues(alpha: 0.25)
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: isLast ? null : () => _moveItem(index, index + 1),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Tooltip(
                                    message: 'Mover abajo',
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: isLast
                                            ? theme.colorScheme.outline.withValues(alpha: 0.25)
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 2),

                            // 3. Número secuencial
                            Container(
                              width: 24,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 4. Contenido de nombre y detalles clínicos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          test.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (test.code != null && test.code!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
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
                                      if (test.isProfileParameter) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Parámetro',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        refSummary,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (test.subclassification.isNotEmpty) ...[
                                        const Text(' • ',
                                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(
                                          test.subclassification,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.tertiary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 5. Botón de Edición (Lápiz)
                            if (widget.onEditTest != null)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: theme.colorScheme.primary,
                                tooltip: 'Editar parámetro "${test.name}"',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => widget.onEditTest!(test),
                              ),

                            // 6. Botón de Remover de este perfil
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              color: theme.colorScheme.error,
                              tooltip: 'Quitar de este perfil',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _toggleTest(test.id, false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _getCategories();
    final filteredTests = _getFilteredItems();

    // Cálculos de precios acumulados manteniendo el orden de selectedTestIds
    final selectedTests = <LabTestInDb>[];
    for (final id in widget.selectedTestIds) {
      final found = widget.availableTests.where((t) => t.id == id).firstOrNull;
      if (found != null) {
        selectedTests.add(found);
      }
    }
    final totalIndividualCents = selectedTests.fold<int>(0, (sum, t) => sum + t.salePrice);
    final totalIndividualPrice = totalIndividualCents / 100.0;
    final packPrice = widget.packSalePrice;
    final savings = totalIndividualPrice - packPrice;

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sección Superior: Parámetros y Análisis Seleccionados en este Perfil
          _buildSelectedTestsSection(context, theme, selectedTests),
          const Divider(height: 1),

          // 2. Cabecera y Buscador del Catálogo para Agregar Más Pruebas
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Agregar Más Análisis desde el Catálogo',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

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

                      return Material(
                        type: MaterialType.transparency,
                        child: CheckboxListTile(
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
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
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
                                if (test.subclassification.isNotEmpty) ...[
                                  const Text(' • ',
                                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    test.subclassification,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                                if (test.unitOfMeasure.isNotEmpty) ...[
                                  const Text(' • ',
                                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    test.unitOfMeasure,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (test.isProfileParameter) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Parámetro',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                          widget.useChildTestsPriceSum
                              ? 'Precio del Pack = Sumatoria: \$${packPrice.toStringAsFixed(2)} USD'
                              : (savings > 0
                                  ? 'Ahorro al cliente: \$${savings.toStringAsFixed(2)} USD'
                                  : 'Precio del Pack: \$${packPrice.toStringAsFixed(2)} USD'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: widget.useChildTestsPriceSum
                                ? theme.colorScheme.primary
                                : (savings > 0
                                    ? Colors.green.shade800
                                    : theme.colorScheme.primary),
                          ),
                        ),
                        if (!widget.useChildTestsPriceSum && savings > 0 && totalIndividualPrice > 0)
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
