import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/search_lab_tests_cubit.dart';
import '../../../cubits/lab_test_cubit/write_lab_tests_cubit.dart';
import '../widgets/lab_tests_list.dart';
import '../widgets/lab_test_form_dialog.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(BuildContext context, String query) {
    if (query.trim().isEmpty) {
      context.read<SearchLabTestCubit>().search('');
    } else {
      context.read<SearchLabTestCubit>().search(query);
    }
  }

  void _openLabTestForm(BuildContext context, [LabTestInDb? labTest]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteLabTestCubit>(context),
          child: LabTestFormDialog(labTest: labTest),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadLabTestCubit>().getAll();
      }
    });
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
            SnackBar(content: Text('Error: ${state.message}'), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      child: Column(
        children: [
          // Header Bar
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
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pruebas de Laboratorio',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catálogo general de parámetros y pruebas del sistema LIS',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Search Input
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _onSearchChanged(context, val),
                    decoration: InputDecoration(
                      hintText: 'Buscar prueba...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openLabTestForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Prueba'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lab Tests List Container
          Expanded(
            child: BlocBuilder<SearchLabTestCubit, SearchLabTestState>(
              builder: (context, searchState) {
                if (searchState is SearchLabTestSuccess && _searchController.text.trim().isNotEmpty) {
                  return LabTestsList(
                    labTests: searchState.items,
                    onEdit: (labTest) => _openLabTestForm(context, labTest),
                  );
                }

                // Default fallback to read all lab tests
                return BlocBuilder<ReadLabTestCubit, ReadLabTestState>(
                  builder: (context, readState) {
                    if (readState is ReadLabTestLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (readState is ReadLabTestSuccess) {
                      return LabTestsList(
                        labTests: readState.items,
                        onEdit: (labTest) => _openLabTestForm(context, labTest),
                      );
                    } else if (readState is ReadLabTestError) {
                      return Center(
                        child: Text(
                          'Error al cargar pruebas: ${readState.message}',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }
                    return const Center(child: Text('Cargando catálogo...'));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
