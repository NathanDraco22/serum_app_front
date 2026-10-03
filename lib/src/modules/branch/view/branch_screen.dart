import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/branch_cubit/read_branches_cubit.dart';
import '../../../cubits/branch_cubit/write_branches_cubit.dart';
import '../widgets/branches_list.dart';
import '../widgets/branch_form_dialog.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadBranchCubit>(
          create: (context) => ReadBranchCubit(
            branchesRepository:
                RepositoryProvider.of<BranchesRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteBranchCubit>(
          create: (context) => WriteBranchCubit(
            branchesRepository:
                RepositoryProvider.of<BranchesRepository>(context),
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
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBranchForm(BuildContext context, [BranchInDb? branch]) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteBranchCubit>(context),
          child: BranchFormDialog(branch: branch),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadBranchCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteBranchCubit, WriteBranchState>(
      listener: (context, state) {
        if (state is BranchCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sucursal registrada con éxito')),
          );
        } else if (state is BranchUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sucursal actualizada con éxito')),
          );
        } else if (state is BranchDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sucursal eliminada con éxito')),
          );
        } else if (state is WriteBranchError) {
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
          // Full Screen Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
            ),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver a Administración',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),

                // Icon and Titles
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store_mall_directory_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sucursales / Sedes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Catálogo y control de las sedes de atención del laboratorio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Search Bar
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o dirección...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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

                // Add Button
                ElevatedButton.icon(
                  onPressed: () => _openBranchForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Sucursal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: BlocBuilder<ReadBranchCubit, ReadBranchState>(
              builder: (context, readState) {
                if (readState is ReadBranchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadBranchSuccess) {
                  final filteredBranches = _searchQuery.isEmpty
                      ? readState.items
                      : readState.items.where((b) {
                          return b.name.toLowerCase().contains(_searchQuery) ||
                              b.address.toLowerCase().contains(_searchQuery) ||
                              b.phone.toLowerCase().contains(_searchQuery);
                        }).toList();

                  return BranchesList(
                    branches: filteredBranches,
                    onEdit: (branch) => _openBranchForm(context, branch),
                  );
                } else if (readState is ReadBranchError) {
                  return Center(
                    child: Text(
                      'Error al cargar sucursales: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando sucursales...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
