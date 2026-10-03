import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/branch_cubit/read_branches_cubit.dart';
import '../../../cubits/user_cubit/read_users_cubit.dart';
import '../../../cubits/user_cubit/write_users_cubit.dart';
import '../widgets/users_list.dart';
import '../widgets/user_form_dialog.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReadUserCubit>(
          create: (context) => ReadUserCubit(
            usersRepository: RepositoryProvider.of<UsersRepository>(context),
          )..getAll(),
        ),
        BlocProvider<WriteUserCubit>(
          create: (context) => WriteUserCubit(
            usersRepository: RepositoryProvider.of<UsersRepository>(context),
          ),
        ),
        BlocProvider<ReadBranchCubit>(
          create: (context) => ReadBranchCubit(
            branchesRepository:
                RepositoryProvider.of<BranchesRepository>(context),
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
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUserForm(BuildContext context, [UserInDb? user]) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: BlocProvider.of<WriteUserCubit>(context),
            ),
            BlocProvider.value(
              value: BlocProvider.of<ReadBranchCubit>(context),
            ),
          ],
          child: UserFormDialog(user: user),
        );
      },
    ).then((value) {
      if (value == true && context.mounted) {
        context.read<ReadUserCubit>().getAll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<WriteUserCubit, WriteUserState>(
      listener: (context, state) {
        if (state is UserCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario registrado con éxito')),
          );
        } else if (state is UserUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario actualizado con éxito')),
          );
        } else if (state is UserDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado con éxito')),
          );
        } else if (state is WriteUserError) {
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
                    color: theme.colorScheme.secondaryContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.manage_accounts_rounded,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuarios y Cuentas',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Control de credenciales, roles operativos y sedes asignadas al personal',
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
                      hintText: 'Buscar por nombre, usuario o rol...',
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
                  onPressed: () => _openUserForm(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Nuevo Usuario'),
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
            child: BlocBuilder<ReadUserCubit, ReadUserState>(
              builder: (context, readState) {
                if (readState is ReadUserLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (readState is ReadUserSuccess) {
                  final nonInternalUsers =
                      readState.items.where((u) => !u.isInternal).toList();
                  final filteredUsers = _searchQuery.isEmpty
                      ? nonInternalUsers
                      : nonInternalUsers.where((u) {
                          return u.name.toLowerCase().contains(_searchQuery) ||
                              u.username.toLowerCase().contains(_searchQuery) ||
                              u.role.toLowerCase().contains(_searchQuery) ||
                              (u.email?.toLowerCase().contains(_searchQuery) ??
                                  false);
                        }).toList();

                  return UsersList(
                    users: filteredUsers,
                    onEdit: (user) => _openUserForm(context, user),
                  );
                } else if (readState is ReadUserError) {
                  return Center(
                    child: Text(
                      'Error al cargar usuarios: ${readState.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }
                return const Center(child: Text('Cargando colaboradores...'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
