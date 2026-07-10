import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/patient_cubit/read_patients_cubit.dart';
import '../../../cubits/patient_cubit/search_patients_cubit.dart';
import '../../../cubits/patient_cubit/write_patients_cubit.dart';
import '../widgets/patients_list.dart';
import '../widgets/patient_form_dialog.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadPatientCubit>(
          create: (context) => ReadPatientCubit(
            patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<SearchPatientCubit>(
          create: (context) => SearchPatientCubit(
            patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
          ),
        ),
        BlocProvider<WritePatientCubit>(
          create: (context) => WritePatientCubit(
            patientsRepository: RepositoryProvider.of<PatientsRepository>(context),
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
      context.read<SearchPatientCubit>().search('');
    } else {
      context.read<SearchPatientCubit>().search(query);
    }
  }

  void _openPatientForm(BuildContext context, [PatientInDb? patient]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WritePatientCubit>(context),
          child: PatientFormDialog(patient: patient),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadPatientCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WritePatientCubit, WritePatientState>(
      listener: (context, state) {
        if (state is PatientCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente creado con éxito')),
          );
        } else if (state is PatientUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente actualizado con éxito')),
          );
        } else if (state is PatientDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente eliminado con éxito')),
          );
        } else if (state is WritePatientError) {
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
                      'Pacientes',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestión del catálogo de pacientes del laboratorio',
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
                      hintText: 'Buscar paciente...',
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
                  onPressed: () => _openPatientForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Paciente'),
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
          // Patients List Container
          Expanded(
            child: BlocBuilder<SearchPatientCubit, SearchPatientState>(
              builder: (context, searchState) {
                if (searchState is SearchPatientSuccess && _searchController.text.trim().isNotEmpty) {
                  return PatientsList(
                    patients: searchState.items,
                    onEdit: (patient) => _openPatientForm(context, patient),
                  );
                }

                // Default fallback to read all patients
                return BlocBuilder<ReadPatientCubit, ReadPatientState>(
                  builder: (context, readState) {
                    if (readState is ReadPatientLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (readState is ReadPatientSuccess) {
                      return PatientsList(
                        patients: readState.items,
                        onEdit: (patient) => _openPatientForm(context, patient),
                      );
                    } else if (readState is ReadPatientError) {
                      return Center(
                        child: Text(
                          'Error al cargar pacientes: ${readState.message}',
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
