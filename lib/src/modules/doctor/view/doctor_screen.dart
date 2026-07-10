import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/doctor_cubit/read_doctors_cubit.dart';
import '../../../cubits/doctor_cubit/search_doctors_cubit.dart';
import '../../../cubits/doctor_cubit/write_doctors_cubit.dart';
import '../widgets/doctors_list.dart';
import '../widgets/doctor_form_dialog.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadDoctorCubit>(
          create: (context) => ReadDoctorCubit(
            doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
          )..getAll(),
        ),
        BlocProvider<SearchDoctorCubit>(
          create: (context) => SearchDoctorCubit(
            doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
          ),
        ),
        BlocProvider<WriteDoctorCubit>(
          create: (context) => WriteDoctorCubit(
            doctorsRepository: RepositoryProvider.of<DoctorsRepository>(context),
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
      context.read<SearchDoctorCubit>().search('');
    } else {
      context.read<SearchDoctorCubit>().search(query);
    }
  }

  void _openDoctorForm(BuildContext context, [DoctorInDb? doctor]) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteDoctorCubit>(context),
          child: DoctorFormDialog(doctor: doctor),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadDoctorCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteDoctorCubit, WriteDoctorState>(
      listener: (context, state) {
        if (state is DoctorCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médico creado con éxito')),
          );
        } else if (state is DoctorUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médico actualizado con éxito')),
          );
        } else if (state is DoctorDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médico eliminado con éxito')),
          );
        } else if (state is WriteDoctorError) {
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
                      'Médicos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catálogo y registro de médicos autorizados',
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
                      hintText: 'Buscar médico...',
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
                  onPressed: () => _openDoctorForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Médico'),
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
          // Doctors List Container
          Expanded(
            child: BlocBuilder<SearchDoctorCubit, SearchDoctorState>(
              builder: (context, searchState) {
                if (searchState is SearchDoctorSuccess && _searchController.text.trim().isNotEmpty) {
                  return DoctorsList(
                    doctors: searchState.items,
                    onEdit: (doctor) => _openDoctorForm(context, doctor),
                  );
                }

                // Default fallback to read all doctors
                return BlocBuilder<ReadDoctorCubit, ReadDoctorState>(
                  builder: (context, readState) {
                    if (readState is ReadDoctorLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (readState is ReadDoctorSuccess) {
                      return DoctorsList(
                        doctors: readState.items,
                        onEdit: (doctor) => _openDoctorForm(context, doctor),
                      );
                    } else if (readState is ReadDoctorError) {
                      return Center(
                        child: Text(
                          'Error al cargar médicos: ${readState.message}',
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
