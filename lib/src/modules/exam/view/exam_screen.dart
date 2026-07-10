import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../../../cubits/exam_cubit/search_exams_cubit.dart';
import '../../../cubits/exam_cubit/write_exams_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../widgets/exams_list.dart';
import '../widgets/exam_form_dialog.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadExamCubit>(
          create: (context) => ReadExamCubit(
            examsRepository: RepositoryProvider.of<ExamsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<SearchExamCubit>(
          create: (context) => SearchExamCubit(
            examsRepository: RepositoryProvider.of<ExamsRepository>(context),
          ),
        ),
        BlocProvider<WriteExamCubit>(
          create: (context) => WriteExamCubit(
            examsRepository: RepositoryProvider.of<ExamsRepository>(context),
          ),
        ),
        BlocProvider<ReadLabTestCubit>(
          create: (context) => ReadLabTestCubit(
            labTestsRepository: RepositoryProvider.of<LabTestsRepository>(context),
          )..getAll(),
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
      context.read<SearchExamCubit>().search('');
    } else {
      context.read<SearchExamCubit>().search(query);
    }
  }

  void _openExamForm(BuildContext context, [ExamInDb? exam]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<WriteExamCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<ReadLabTestCubit>(context)),
          ],
          child: ExamFormDialog(exam: exam),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadExamCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteExamCubit, WriteExamState>(
      listener: (context, state) {
        if (state is ExamCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Examen creado con éxito')),
          );
        } else if (state is ExamUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Examen actualizado con éxito')),
          );
        } else if (state is ExamDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Examen eliminado con éxito')),
          );
        } else if (state is WriteExamError) {
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
                      'Exámenes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perfiles de exámenes y paneles integrados',
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
                      hintText: 'Buscar examen...',
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
                  onPressed: () => _openExamForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Examen'),
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
          // Exams List Container
          Expanded(
            child: BlocBuilder<SearchExamCubit, SearchExamState>(
              builder: (context, searchState) {
                if (searchState is SearchExamSuccess && _searchController.text.trim().isNotEmpty) {
                  return ExamsList(
                    exams: searchState.items,
                    onEdit: (exam) => _openExamForm(context, exam),
                  );
                }

                // Default fallback to read all exams
                return BlocBuilder<ReadExamCubit, ReadExamState>(
                  builder: (context, readState) {
                    if (readState is ReadExamLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (readState is ReadExamSuccess) {
                      return ExamsList(
                        exams: readState.items,
                        onEdit: (exam) => _openExamForm(context, exam),
                      );
                    } else if (readState is ReadExamError) {
                      return Center(
                        child: Text(
                          'Error al cargar exámenes: ${readState.message}',
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
