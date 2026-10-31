import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/search_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import '../widgets/lab_tests_list.dart';
import 'lab_test_form_screen.dart';
import '../widgets/clinical_classification_registry.dart';
import '../widgets/lab_test_detail_dialog.dart';
import '../widgets/lab_test_quick_price_dialog.dart';
import '../../../widgets/common/app_buttons.dart';

class LabTestsScreen extends StatelessWidget {
  const LabTestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadLabTestCubit>(
          create: (context) => ReadLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          )..getAll(branchId: context.read<AppSessionCubit>().currentBranchId),
        ),
        BlocProvider<SearchLabTestCubit>(
          create: (context) => SearchLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          ),
        ),
        BlocProvider<WriteLabTestCubit>(
          create: (context) => WriteLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          ),
        ),
      ],
      child: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // 'all', 'individual', 'pack', 'parameter'
  String _selectedCategory = 'Todas';
  String _selectedSubclassification = 'Todas';
  bool _hideProfileParameters = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      context.read<SearchLabTestCubit>().clear();
    } else {
      final branchId = context.read<AppSessionCubit>().currentBranchId;
      context.read<SearchLabTestCubit>().search(query.trim(), branchId: branchId);
    }
  }

  void _openLabTestForm(BuildContext context, [LabTestInDb? labTest]) {
    Navigator.of(context, rootNavigator: true)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: BlocProvider.of<WriteLabTestCubit>(context)),
                BlocProvider.value(value: BlocProvider.of<ReadLabTestCubit>(context)),
              ],
              child: LabTestFormScreen(labTest: labTest),
            ),
          ),
        )
        .then((value) {
          if (value == true && context.mounted) {
            _searchController.clear();
            context.read<SearchLabTestCubit>().clear();
            setState(() {
              _selectedCategory = 'Todas';
              _selectedSubclassification = 'Todas';
              _filterType = 'all';
            });
            final branchId = context.read<AppSessionCubit>().currentBranchId;
            context.read<ReadLabTestCubit>().getAll(branchId: branchId);
          }
        });
  }

  void _openLabTestDetail(BuildContext context, LabTestInDb labTest, List<LabTestInDb> allTests) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return LabTestDetailDialog(
          labTest: labTest,
          allLabTests: allTests,
          onEditPrice: (test) {
            Navigator.of(dialogContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _openQuickPriceDialog(context, test);
              }
            });
          },
        );
      },
    );
  }

  void _openQuickPriceDialog(BuildContext context, LabTestInDb labTest) {
    LabTestQuickPriceDialog.show(
      context,
      labTest: labTest,
      branchId: context.read<AppSessionCubit>().currentBranchId,
    );
  }

  List<String> _extractCategories(List<LabTestInDb> tests) {
    final categories = <String>{'Todas'};
    for (final t in tests) {
      if (t.commercialCategory.trim().isNotEmpty) {
        categories.add(t.commercialCategory.trim());
      }
    }
    for (final c in ClinicalClassificationRegistry.classifications) {
      categories.add(c);
    }
    final sorted = categories.toList();
    sorted.sort((a, b) {
      if (a == 'Todas') return -1;
      if (b == 'Todas') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }

  List<String> _extractSubclassifications(
    List<LabTestInDb> tests,
    String selectedCategory,
  ) {
    final subcategories = <String>{'Todas'};
    final hasCategory = selectedCategory != 'Todas';

    for (final t in tests) {
      if (hasCategory &&
          t.commercialCategory.trim().toLowerCase() != selectedCategory.trim().toLowerCase()) {
        continue;
      }
      if (t.subclassification.trim().isNotEmpty) {
        subcategories.add(t.subclassification.trim());
      }
    }

    if (hasCategory) {
      for (final s in ClinicalClassificationRegistry.getSubclassificationsFor(selectedCategory)) {
        subcategories.add(s);
      }
    }

    final sorted = subcategories.toList();
    sorted.sort((a, b) {
      if (a == 'Todas') return -1;
      if (b == 'Todas') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return sorted;
  }

  List<LabTestInDb> _applyFilters(List<LabTestInDb> baseList) {
    final filtered = baseList.where((t) {
      if (_filterType == 'individual' && (t.isPack || t.isProfileParameter)) return false;
      if (_filterType == 'pack' && !t.isPack) return false;
      if (_filterType == 'parameter' && !t.isProfileParameter) return false;
      if (_hideProfileParameters && t.isProfileParameter && _filterType == 'all') {
        return false;
      }
      if (_selectedCategory != 'Todas' &&
          t.commercialCategory.trim().toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_selectedSubclassification != 'Todas' &&
          t.subclassification.trim().toLowerCase() !=
              _selectedSubclassification.trim().toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteLabTestCubit, WriteLabTestState>(
      listener: (context, state) {
        if (state is LabTestCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prueba de laboratorio creada con éxito')),
          );
        } else if (state is LabTestUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prueba de laboratorio actualizada con éxito')),
          );
        } else if (state is LabTestDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prueba de laboratorio eliminada con éxito')),
          );
        } else if (state is WriteLabTestError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<ReadLabTestCubit, ReadLabTestState>(
        builder: (context, readState) {
          final allTests = (readState is ReadLabTestSuccess)
              ? readState.items
              : (readState is ReadLabTestRefreshing)
              ? readState.items
              : <LabTestInDb>[];

          final totalCount = allTests.length;
          final packCount = allTests.where((t) => t.isPack).length;
          final parameterCount = allTests.where((t) => t.isProfileParameter).length;
          final individualCount = totalCount - packCount - parameterCount;
          final categories = _extractCategories(allTests);
          final subcategories = _extractSubclassifications(allTests, _selectedCategory);

          return Column(
            children: [
              // Header Bar con KPIs y Acciones Principales
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catálogo de Pruebas de Laboratorio',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestión de análisis clínicos individuales y perfiles comerciales (Packs)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // KPIs rápidos
                        _KpiBadge(
                          label: 'Total',
                          count: totalCount,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _KpiBadge(
                          label: 'Individuales',
                          count: individualCount,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        _KpiBadge(
                          label: 'Packs',
                          count: packCount,
                          color: theme.colorScheme.tertiary,
                        ),
                        if (parameterCount > 0) ...[
                          const SizedBox(width: 8),
                          _KpiBadge(
                            label: 'Parámetros',
                            count: parameterCount,
                            color: theme.colorScheme.outline,
                          ),
                        ],
                        const SizedBox(width: 16),
                        PrimaryButton(
                          onPressed: () => _openLabTestForm(context),
                          icon: Icons.add,
                          label: 'Nueva Prueba / Pack',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Barra de Filtros: Buscador + SegmentedButton + Chips de Categoría
                    Row(
                      children: [
                        // Search Input
                        SizedBox(
                          width: 320,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => _onSearchChanged(context, val),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre, clave o categoría...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged(context, '');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
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
                        const SizedBox(width: 16),
                        // Filtro de Tipo (Dropdown)
                        SizedBox(
                          width: 250,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_filterType),
                            initialValue: _filterType,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Tipo de análisis',
                              prefixIcon: const Icon(Icons.filter_list, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  'Todos los análisis',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'individual',
                                child: Text(
                                  'Pruebas Individuales',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'pack',
                                child: Text(
                                  'Packs / Perfiles',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'parameter',
                                child: Text(
                                  'Parámetros de Perfiles',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _filterType = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilterChip(
                          avatar: Icon(
                            _hideProfileParameters
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                          ),
                          label: const Text(
                            'Ocultar parámetros de perfil',
                            style: TextStyle(fontSize: 12),
                          ),
                          selected: _hideProfileParameters,
                          onSelected: (val) {
                            setState(() => _hideProfileParameters = val);
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filtros Secundarios: Dropdowns en cascada de Clasificación y Subclasificación
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Dropdown 1: Clasificación General
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('filter_category_$_selectedCategory'),
                            initialValue: categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : 'Todas',
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Clasificación General',
                              prefixIcon: const Icon(Icons.category_outlined, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat == 'Todas' ? 'Todas las clasificaciones' : cat,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                  _selectedSubclassification = 'Todas';
                                });
                              }
                            },
                          ),
                        ),

                        // Dropdown 2: Subclasificación
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'filter_sub_${_selectedCategory}_$_selectedSubclassification',
                            ),
                            initialValue: subcategories.contains(_selectedSubclassification)
                                ? _selectedSubclassification
                                : 'Todas',
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: 'Subclasificación',
                              prefixIcon: const Icon(Icons.subdirectory_arrow_right, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            items: subcategories.map((sub) {
                              return DropdownMenuItem(
                                value: sub,
                                child: Text(
                                  sub == 'Todas' ? 'Todas las subclasificaciones' : sub,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSubclassification = val;
                                });
                              }
                            },
                          ),
                        ),

                        // Botón de Limpiar Filtros
                        if (_selectedCategory != 'Todas' ||
                            _selectedSubclassification != 'Todas')
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = 'Todas';
                                _selectedSubclassification = 'Todas';
                              });
                            },
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text(
                              'Limpiar filtros',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lab Tests List Container
              Expanded(
                child: BlocBuilder<SearchLabTestCubit, SearchLabTestState>(
                  builder: (context, searchState) {
                    if (searchState is SearchLabTestLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<LabTestInDb> testsToDisplay;
                    if (searchState is SearchLabTestSuccess &&
                        _searchController.text.trim().isNotEmpty) {
                      testsToDisplay = _applyFilters(searchState.items);
                    } else {
                      if (readState is ReadLabTestLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (readState is ReadLabTestError) {
                        return Center(
                          child: Text(
                            'Error al cargar pruebas: ${readState.message}',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        );
                      }
                      testsToDisplay = _applyFilters(allTests);
                    }

                    return LabTestsList(
                      labTests: testsToDisplay,
                      allLabTests: allTests,
                      onEdit: (labTest) => _openLabTestForm(context, labTest),
                      onDetail: (labTest) => _openLabTestDetail(context, labTest, allTests),
                      onEditPrice: (labTest) => _openQuickPriceDialog(context, labTest),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _KpiBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
