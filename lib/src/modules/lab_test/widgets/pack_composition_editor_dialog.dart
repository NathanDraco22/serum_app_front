import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import 'pack_test_selector.dart';
import 'quick_create_parameter_dialog.dart';

/// Diálogo modal de doble panel (Dual-Pane / Transfer List) para la selección,
/// ordenamiento analítico y configuración de parámetros/análisis de un perfil clínico (pack).
///
/// Siguiendo los principios de Clinical Precision y el estándar OKF v0.2:
/// - **Panel Izquierdo (~52%)**: Catálogo general con búsqueda en tiempo real, filtros y adición rápida.
/// - **Panel Derecho (~48%)**: Composición del perfil reordenable (drag & drop y ▲▼), con visualización de precios y ahorro.
/// - Permite crear parámetros al vuelo sin abandonar el diálogo mediante [QuickCreateParameterDialog].
class PackCompositionEditorDialog extends StatefulWidget {
  final List<LabTestInDb> availableTests;
  final List<String> initialSelectedIds;
  final String packName;
  final double packSalePrice;
  final bool useChildTestsPriceSum;
  final String branchId;
  final void Function(LabTestInDb test)? onEditTest;
  final Future<LabTestInDb?> Function()? onQuickCreateParameter;

  const PackCompositionEditorDialog({
    super.key,
    required this.availableTests,
    required this.initialSelectedIds,
    this.packName = '',
    required this.packSalePrice,
    this.useChildTestsPriceSum = true,
    required this.branchId,
    this.onEditTest,
    this.onQuickCreateParameter,
  });

  /// Muestra el diálogo modal y retorna la lista ordenada de IDs seleccionados,
  /// o `null` si el usuario canceló la acción.
  static Future<List<String>?> show(
    BuildContext context, {
    required List<LabTestInDb> availableTests,
    required List<String> initialSelectedIds,
    String packName = '',
    required double packSalePrice,
    bool useChildTestsPriceSum = true,
    required String branchId,
    void Function(LabTestInDb test)? onEditTest,
    Future<LabTestInDb?> Function()? onQuickCreateParameter,
  }) {
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PackCompositionEditorDialog(
        availableTests: availableTests,
        initialSelectedIds: initialSelectedIds,
        packName: packName,
        packSalePrice: packSalePrice,
        useChildTestsPriceSum: useChildTestsPriceSum,
        branchId: branchId,
        onEditTest: onEditTest,
        onQuickCreateParameter: onQuickCreateParameter,
      ),
    );
  }

  @override
  State<PackCompositionEditorDialog> createState() => _PackCompositionEditorDialogState();
}

class _PackCompositionEditorDialogState extends State<PackCompositionEditorDialog> {
  late List<LabTestInDb> _allAvailable;
  late List<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  PackSelectorItemTypeFilter _selectedTypeFilter = PackSelectorItemTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _allAvailable = List<LabTestInDb>.from(widget.availableTests);
    _selectedIds = List<String>.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getCategories() {
    final categories = <String>{'Todas'};
    for (final test in _allAvailable) {
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
    final items = _allAvailable.where((test) {
      switch (_selectedTypeFilter) {
        case PackSelectorItemTypeFilter.all:
          break;
        case PackSelectorItemTypeFilter.packs:
          if (!test.isPack) return false;
          break;
        case PackSelectorItemTypeFilter.individual:
          if (test.isPack || test.isProfileParameter) return false;
          break;
        case PackSelectorItemTypeFilter.parameters:
          if (test.isPack || !test.isProfileParameter) return false;
          break;
      }

      if (_selectedCategory != 'Todas' &&
          test.commercialCategory.trim() != _selectedCategory) {
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

  void _addTest(String id) {
    if (!_selectedIds.contains(id)) {
      setState(() {
        _selectedIds.add(id);
      });
    }
  }

  void _removeTest(String id) {
    setState(() {
      _selectedIds.remove(id);
    });
  }

  void _toggleTest(String id) {
    if (_selectedIds.contains(id)) {
      _removeTest(id);
    } else {
      _addTest(id);
    }
  }

  void _selectAllFiltered(List<LabTestInDb> filtered) {
    setState(() {
      for (final test in filtered) {
        if (!_selectedIds.contains(test.id)) {
          _selectedIds.add(test.id);
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _selectedIds.removeAt(oldIndex);
      _selectedIds.insert(newIndex, item);
    });
  }

  void _moveItem(int currentIndex, int targetIndex) {
    if (currentIndex < 0 || currentIndex >= _selectedIds.length) return;
    if (targetIndex < 0 || targetIndex >= _selectedIds.length) return;
    setState(() {
      final item = _selectedIds.removeAt(currentIndex);
      _selectedIds.insert(targetIndex, item);
    });
  }

  Future<void> _handleQuickCreateParameter() async {
    LabTestInDb? created;
    if (widget.onQuickCreateParameter != null) {
      created = await widget.onQuickCreateParameter!();
    } else {
      final cat = _selectedCategory != 'Todas' ? _selectedCategory : 'Hematología';
      created = await QuickCreateParameterDialog.show(
        context,
        initialCategory: cat,
        branchId: widget.branchId,
      );
    }

    if (created != null && mounted) {
      setState(() {
        _allAvailable.add(created!);
        if (!_selectedIds.contains(created.id)) {
          _selectedIds.add(created.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parámetro "${created.name}" creado y añadido al perfil.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  String _formatReferenceSummary(LabTestInDb test) {
    if (test.isPack) {
      final count = test.childTestIds.length;
      return count > 0 ? '$count análisis incluidos' : 'Pack comercial';
    }
    if (test.dataType == 'numeric') {
      final unit = test.unitOfMeasure.isNotEmpty ? ' ${test.unitOfMeasure}' : '';
      if (test.referenceValues.isNotEmpty) {
        if (test.referenceValues.length > 1) {
          return 'Ref: ${test.referenceValues.length} rangos configurados';
        }
        final ref = test.referenceValues.first;
        final minStr = ref.minValue % 1 == 0
            ? ref.minValue.toInt().toString()
            : ref.minValue.toString();
        final maxStr = ref.maxValue % 1 == 0
            ? ref.maxValue.toInt().toString()
            : ref.maxValue.toString();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _getCategories();
    final filteredTests = _getFilteredItems();

    // Resolver objetos seleccionados manteniendo el orden de _selectedIds
    final selectedTests = <LabTestInDb>[];
    for (final id in _selectedIds) {
      final found = _allAvailable.where((t) => t.id == id).firstOrNull;
      if (found != null) {
        selectedTests.add(found);
      }
    }

    final totalIndividualCents = selectedTests.fold<int>(0, (sum, t) => sum + t.salePrice);
    final totalIndividualPrice = totalIndividualCents / 100.0;
    final packPrice = widget.packSalePrice;
    final savings = totalIndividualPrice - packPrice;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1180,
          maxHeight: 760,
          minWidth: 600,
          minHeight: 480,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabecera Principal del Diálogo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editor de Composición del Perfil Clínico',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.packName.isNotEmpty
                              ? 'Configurando: ${widget.packName}'
                              : 'Seleccione y organice los análisis incluidos en este paquete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cerrar sin guardar',
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            // 2. Cuerpo Dual-Pane (Izquierda: Catálogo | Derecha: Composición)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- PANEL IZQUIERDO: Catálogo Disponible (~54%) ---
                  Expanded(
                    flex: 54,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabecera del Panel Izquierdo con botón "Crear Parámetro"
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Catálogo Disponible',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                onPressed: _handleQuickCreateParameter,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Crear Parámetro'),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Barra de Búsqueda
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o código (ej. Glucosa, GLU)...',
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                          ),
                        ),

                        // Chips de Tipo de Estudio
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Todos', style: TextStyle(fontSize: 11)),
                                  selected: _selectedTypeFilter == PackSelectorItemTypeFilter.all,
                                  onSelected: (_) => setState(
                                    () => _selectedTypeFilter = PackSelectorItemTypeFilter.all,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  avatar: const Icon(Icons.inventory_2, size: 13),
                                  label: const Text('Perfiles', style: TextStyle(fontSize: 11)),
                                  selected: _selectedTypeFilter == PackSelectorItemTypeFilter.packs,
                                  onSelected: (_) => setState(
                                    () => _selectedTypeFilter = PackSelectorItemTypeFilter.packs,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  avatar: const Icon(Icons.science, size: 13),
                                  label: const Text('Individuales', style: TextStyle(fontSize: 11)),
                                  selected: _selectedTypeFilter ==
                                      PackSelectorItemTypeFilter.individual,
                                  onSelected: (_) => setState(
                                    () => _selectedTypeFilter =
                                        PackSelectorItemTypeFilter.individual,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  avatar: const Icon(Icons.tune, size: 13),
                                  label: const Text('Parámetros', style: TextStyle(fontSize: 11)),
                                  selected: _selectedTypeFilter ==
                                      PackSelectorItemTypeFilter.parameters,
                                  onSelected: (_) => setState(
                                    () => _selectedTypeFilter =
                                        PackSelectorItemTypeFilter.parameters,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chips de Categorías Comerciales
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: categories.map((cat) {
                                final isSelected = _selectedCategory == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                                    selected: isSelected,
                                    onSelected: (_) => setState(() => _selectedCategory = cat),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // Barra de conteo y selección visible
                        Container(
                          color: theme.colorScheme.surfaceContainerLow,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                'Mostrando ${filteredTests.length} de ${_allAvailable.length}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              if (filteredTests.isNotEmpty)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () => _selectAllFiltered(filteredTests),
                                  icon: const Icon(Icons.select_all, size: 15),
                                  label: const Text(
                                    'Seleccionar visibles',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Lista Virtualizada del Catálogo
                        Expanded(
                          child: filteredTests.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 36,
                                          color: theme.colorScheme.outline,
                                        ),
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
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: filteredTests.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    indent: 48,
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  itemBuilder: (context, index) {
                                    final test = filteredTests[index];
                                    final isAdded = _selectedIds.contains(test.id);
                                    final testPrice =
                                        NumberFormatter.convertToMoneyLike(test.salePrice);

                                    return InkWell(
                                      onTap: () => _toggleTest(test.id),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            // Icono de estado / Adición
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: isAdded
                                                    ? Colors.green.shade50
                                                    : theme.colorScheme.surfaceContainerHighest,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isAdded
                                                      ? Colors.green.shade400
                                                      : theme.colorScheme.outlineVariant,
                                                ),
                                              ),
                                              child: Icon(
                                                isAdded
                                                    ? Icons.check
                                                    : Icons.add,
                                                size: 16,
                                                color: isAdded
                                                    ? Colors.green.shade700
                                                    : theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),

                                            // Nombre y detalles clínicos
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          test.name,
                                                          style: TextStyle(
                                                            fontWeight: isAdded
                                                                ? FontWeight.bold
                                                                : FontWeight.w600,
                                                            fontSize: 13,
                                                            color: isAdded
                                                                ? theme.colorScheme.primary
                                                                : theme.colorScheme.onSurface,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (test.code != null &&
                                                          test.code!.isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 1,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: theme.colorScheme
                                                                .surfaceContainerHigh,
                                                            borderRadius:
                                                                BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            test.code!,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontFamily: 'monospace',
                                                              color: theme.colorScheme
                                                                  .onSurfaceVariant,
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
                                                            style: TextStyle(
                                                                fontSize: 10, color: Colors.grey)),
                                                        Text(
                                                          test.subclassification,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w500,
                                                            color: theme.colorScheme.tertiary,
                                                          ),
                                                        ),
                                                      ],
                                                      if (test.unitOfMeasure.isNotEmpty) ...[
                                                        const Text(' • ',
                                                            style: TextStyle(
                                                                fontSize: 10, color: Colors.grey)),
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
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Precio y Badge de Estado
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  testPrice,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: isAdded
                                                        ? theme.colorScheme.primary
                                                        : theme.colorScheme.secondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                if (isAdded)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(
                                                        color: Colors.green.shade300,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Agregado',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green.shade800,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    '+ Añadir',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  // Separador Vertical entre Paneles
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),

                  // --- PANEL DERECHO: Composición del Perfil (~46%) ---
                  Expanded(
                    flex: 46,
                    child: Container(
                      color: theme.colorScheme.surfaceContainerLowest,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Cabecera del Panel Derecho
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.playlist_add_check_circle_outlined,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Contenido del Perfil',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
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
                                        '${_selectedIds.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_selectedIds.isNotEmpty)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      foregroundColor: theme.colorScheme.error,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    onPressed: _clearSelection,
                                    icon: const Icon(Icons.clear_all, size: 15),
                                    label: const Text('Quitar todos', style: TextStyle(fontSize: 11)),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Arrastre con ≡ o use ▲▼ para definir el orden clínico de captura e impresión.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),

                          // Lista Reordenable de Análisis en el Perfil
                          Expanded(
                            child: selectedTests.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.touch_app_outlined,
                                            size: 40,
                                            color: theme.colorScheme.outline,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Aún no hay análisis en este perfil.',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Busca en el catálogo de la izquierda y haz clic en "+" para añadirlos.',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    buildDefaultDragHandles: false,
                                    itemCount: selectedTests.length,
                                    onReorderItem: _onReorderItem,
                                    itemBuilder: (context, index) {
                                      final test = selectedTests[index];
                                      final isFirst = index == 0;
                                      final isLast = index == selectedTests.length - 1;
                                      final refSummary = _formatReferenceSummary(test);

                                      return Container(
                                        key: ValueKey(test.id),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: theme.colorScheme.outlineVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              // Handle de Arrastre
                                              ReorderableDragStartListener(
                                                index: index,
                                                child: Tooltip(
                                                  message: 'Arrastre para reordenar',
                                                  child: MouseRegion(
                                                    cursor: SystemMouseCursors.grab,
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                      child: Icon(
                                                        Icons.drag_indicator_rounded,
                                                        size: 20,
                                                        color: theme.colorScheme.outline,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Botones de Subir y Bajar
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: isFirst
                                                        ? null
                                                        : () => _moveItem(index, index - 1),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Icon(
                                                      Icons.arrow_drop_up_rounded,
                                                      size: 18,
                                                      color: isFirst
                                                          ? theme.colorScheme.outline
                                                              .withValues(alpha: 0.25)
                                                          : theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: isLast
                                                        ? null
                                                        : () => _moveItem(index, index + 1),
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Icon(
                                                      Icons.arrow_drop_down_rounded,
                                                      size: 18,
                                                      color: isLast
                                                          ? theme.colorScheme.outline
                                                              .withValues(alpha: 0.25)
                                                          : theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 4),

                                              // Número secuencial
                                              Container(
                                                width: 22,
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
                                              const SizedBox(width: 6),

                                              // Nombre y metadatos
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
                                                              fontSize: 12,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (test.code != null &&
                                                            test.code!.isNotEmpty) ...[
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            test.code!,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontFamily: 'monospace',
                                                              color: theme
                                                                  .colorScheme.onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 1),
                                                    Text(
                                                      refSummary,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),

                                              // Botón de Edición (si está disponible)
                                              if (widget.onEditTest != null)
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                                  color: theme.colorScheme.primary,
                                                  tooltip: 'Editar parámetro "${test.name}"',
                                                  visualDensity: VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(
                                                    minWidth: 28,
                                                    minHeight: 28,
                                                  ),
                                                  onPressed: () => widget.onEditTest!(test),
                                                ),

                                              // Botón para quitar de la lista
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  size: 18,
                                                ),
                                                color: theme.colorScheme.error,
                                                tooltip: 'Quitar de este perfil',
                                                visualDensity: VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 28,
                                                  minHeight: 28,
                                                ),
                                                onPressed: () => _removeTest(test.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Barra de Resumen Financiero Inferior del Panel Derecho
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                              border: Border(
                                top: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${selectedTests.length} análisis incluidos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Suma individual: ${NumberFormatter.currencyFormat.format(totalIndividualPrice)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                if (selectedTests.isNotEmpty && packPrice > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: savings > 0
                                          ? Colors.green.shade50
                                          : theme.colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: savings > 0
                                            ? Colors.green.shade400
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Text(
                                      widget.useChildTestsPriceSum
                                          ? 'Precio = Suma: ${NumberFormatter.currencyFormat.format(packPrice)}'
                                          : (savings > 0
                                              ? 'Ahorro: ${NumberFormatter.currencyFormat.format(savings)}'
                                              : 'Precio: ${NumberFormatter.currencyFormat.format(packPrice)}'),
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
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Barra Inferior de Acciones del Diálogo (Footer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} análisis listos para el perfil',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_selectedIds),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text('Aplicar Selección (${_selectedIds.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
