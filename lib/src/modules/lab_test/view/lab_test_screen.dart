import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/search_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import '../widgets/lab_tests_list.dart';
import 'lab_test_form_screen.dart';
import '../widgets/lab_test_detail_dialog.dart';
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
          )..getAll(),
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
  String _filterType = 'all'; // 'all', 'individual', 'pack'
  String _selectedCategory = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      context.read<SearchLabTestCubit>().clear();
    } else {
      context.read<SearchLabTestCubit>().search(query.trim());
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
              _filterType = 'all';
            });
            context.read<ReadLabTestCubit>().getAll();
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
        );
      },
    );
  }

  List<String> _extractCategories(List<LabTestInDb> tests) {
    final categories = <String>{'Todas'};
    for (final t in tests) {
      if (t.commercialCategory.trim().isNotEmpty) {
        categories.add(t.commercialCategory.trim());
      }
    }
    return categories.toList();
  }

  List<LabTestInDb> _applyFilters(List<LabTestInDb> baseList) {
    return baseList.where((t) {
      if (_filterType == 'individual' && t.isPack) return false;
      if (_filterType == 'pack' && !t.isPack) return false;
      if (_selectedCategory != 'Todas' && t.commercialCategory.trim() != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
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
          final individualCount = totalCount - packCount;
          final categories = _extractCategories(allTests);

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
                          width: 240,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(_filterType),
                            initialValue: _filterType,
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
                              DropdownMenuItem(value: 'all', child: Text('Todos los análisis')),
                              DropdownMenuItem(
                                value: 'individual',
                                child: Text('Pruebas Individuales'),
                              ),
                              DropdownMenuItem(value: 'pack', child: Text('Packs / Perfiles')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _filterType = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chips de Categorías Comerciales
                    if (categories.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(cat, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = cat);
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
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
