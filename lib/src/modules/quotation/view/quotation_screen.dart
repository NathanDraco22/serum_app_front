import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/quotation_cubit/read_quotations_cubit.dart';
import '../../../cubits/quotation_cubit/write_quotations_cubit.dart';
import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/exam_cubit/read_exams_cubit.dart';
import '../widgets/quotations_list.dart';
import '../widgets/quotation_form_dialog.dart';

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
        BlocProvider<ReadExamCubit>(
          create: (context) => ReadExamCubit(
            examsRepository: RepositoryProvider.of<ExamsRepository>(context),
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
  void _openQuotationForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: BlocProvider.of<WriteQuotationCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<ReadPatientCubit>(context)),
            BlocProvider.value(value: BlocProvider.of<ReadExamCubit>(context)),
          ],
          child: const QuotationFormDialog(),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadQuotationCubit>().getAll();
      }
    });
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
                      'Cotizaciones',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Presupuestos y cotizaciones de exámenes clínicos',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openQuotationForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Cotización'),
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
          // Quotations List
          Expanded(
            child: BlocBuilder<ReadQuotationCubit, ReadQuotationState>(
              builder: (context, readState) {
                if (readState is ReadQuotationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadQuotationSuccess) {
                  final quotations = readState.items;
                  if (quotations.isEmpty) {
                    return const Center(child: Text('No hay cotizaciones registradas'));
                  }
                  return QuotationsList(quotations: quotations);
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
