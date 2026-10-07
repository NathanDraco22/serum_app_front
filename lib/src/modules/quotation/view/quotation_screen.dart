import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_router.dart';
import '../../../cubits/quotation_cubit/read_quotations_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/doctor_cubit/read_doctors_cubit.dart';
import '../../../cubits/lab_test_cubit/read_lab_tests_cubit.dart';
import '../widgets/quotations_list.dart';

class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadQuotationCubit>(
          create: (context) => ReadQuotationCubit(
            quotationsRepository: RepositoryProvider.of<QuotationsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteQuotationCubit>(
          create: (context) => WriteQuotationCubit(
            quotationsRepository: RepositoryProvider.of<QuotationsRepository>(context),
          ),
        ),
        BlocProvider<ReadPatientCubit>(
          create: (context) => ReadPatientCubit(
            patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<ReadDoctorCubit>(
          create: (context) => ReadDoctorCubit(
            doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
          )..getAll(),
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

  void _openQuotationForm(BuildContext context) {
    context.push<bool>(AppRouter.createQuotation).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadQuotationCubit>().getAll();
      }
    });
  }

  List<QuotationInDb> _applyFilters(List<QuotationInDb> baseList) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return baseList;

    return baseList.where((quote) {
      final matchClient = quote.clientName.toLowerCase().contains(query);
      final matchId = quote.id.toLowerCase().contains(query);
      final matchExam = quote.exams.any((e) => e.name.toLowerCase().contains(query));

      return matchClient || matchId || matchExam;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteQuotationCubit, WriteQuotationState>(
      listener: (context, state) {
        if (state is QuotationCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización creada con éxito')),
          );
        } else if (state is QuotationUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización actualizada con éxito')),
          );
        } else if (state is QuotationDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cotización eliminada con éxito')),
          );
        } else if (state is WriteQuotationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.message}'),
              backgroundColor: theme.colorScheme.error,
            ),
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
                      'Cotizaciones y Presupuestos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preventa de análisis clínicos con exportación e impresión a PDF',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Últimos 30 días',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Recargar cotizaciones',
                  onPressed: () {
                    context.read<ReadQuotationCubit>().getAll();
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _openQuotationForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Cotización'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                // Buscador
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente, folio o análisis...',
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
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quotations List
          Expanded(
            child: BlocBuilder<ReadQuotationCubit, ReadQuotationState>(
              builder: (context, readState) {
                if (readState is ReadQuotationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadQuotationSuccess) {
                  final filteredList = _applyFilters(readState.items);
                  return QuotationsList(quotations: filteredList);
                } else if (readState is ReadQuotationError) {
                  return Center(
                    child: Text(
                      'Error al cargar cotizaciones: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando cotizaciones...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
