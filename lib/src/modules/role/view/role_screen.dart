import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/role_cubit/read_roles_cubit.dart';
import '../../../cubits/role_cubit/write_roles_cubit.dart';
import '../widgets/role_form_dialog.dart';
import '../widgets/roles_list.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadRoleCubit>(
          create: (context) => ReadRoleCubit(
            rolesRepository: RepositoryProvider.of<RolesRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteRoleCubit>(
          create: (context) => WriteRoleCubit(
            rolesRepository: RepositoryProvider.of<RolesRepository>(context),
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

  void _openRoleForm(BuildContext context, [RoleInDb? role]) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: BlocProvider.of<WriteRoleCubit>(context),
          child: RoleFormDialog(role: role),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadRoleCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteRoleCubit, WriteRoleState>(
      listener: (context, state) {
        if (state is RoleCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol registrado con éxito')),
          );
        } else if (state is RoleUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol actualizado con éxito')),
          );
        } else if (state is RoleDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rol eliminado con éxito')),
          );
        } else if (state is WriteRoleError) {
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
                    Icons.admin_panel_settings_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roles y Niveles de Acceso',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Catálogo de perfiles y jerarquía de niveles de acceso (1 al 5)',
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
                      hintText: 'Buscar rol por nombre o nivel...',
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
                  onPressed: () => _openRoleForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Rol'),
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
            child: BlocBuilder<ReadRoleCubit, ReadRoleState>(
              builder: (context, readState) {
                if (readState is ReadRoleLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadRoleSuccess) {
                  final filteredRoles = _searchQuery.isEmpty
                      ? readState.items
                      : readState.items.where((r) {
                          return r.name.toLowerCase().contains(_searchQuery) ||
                              (r.description
                                      ?.toLowerCase()
                                      .contains(_searchQuery) ??
                                  false) ||
                              r.accessLevel.toString().contains(_searchQuery);
                        }).toList();

                  return RolesList(
                    roles: filteredRoles,
                    onEdit: (role) => _openRoleForm(context, role),
                  );
                } else if (readState is ReadRoleError) {
                  return Center(
                    child: Text(
                      'Error al cargar roles: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando roles...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
