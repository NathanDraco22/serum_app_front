import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/branch_cubit/read_branches_cubit.dart';
import '../../../cubits/user_cubit/write_users_cubit.dart';

class UsersList extends StatelessWidget {
  const UsersList({
    super.key,
    required this.users,
    required this.onEdit,
  });

  final List<UserInDb> users;
  final void Function(UserInDb user) onEdit;

  void _confirmDelete(BuildContext context, UserInDb user) {
    final theme = Theme.of(context);
    final writeCubit = context.read<WriteUserCubit>();

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Eliminar Usuario'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la cuenta de "${user.name}" (@${user.username})?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              writeCubit.delete(user.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role, ColorScheme colorScheme) {
    switch (role.toLowerCase()) {
      case 'admin':
        return colorScheme.primary;
      case 'cashier':
        return Colors.teal;
      case 'bioanalyst':
        return Colors.indigo;
      case 'doctor':
        return Colors.deepPurple;
      default:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branchesState = context.watch<ReadBranchCubit>().state;
    final branchesMap = <String, String>{};
    if (branchesState is ReadBranchSuccess) {
      for (final b in branchesState.items) {
        branchesMap[b.id] = b.name;
      }
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un nuevo colaborador o ajusta los criterios de búsqueda.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final roleColor = _getRoleColor(user.role, theme.colorScheme);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor.withAlpha(30),
                  foregroundColor: roleColor,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + badges
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '@${user.username}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          // Badge Rol
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: roleColor.withAlpha(80),
                              ),
                            ),
                            child: Text(
                              '${user.role.toUpperCase()} • LVL ${user.accessLevel}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Badge Activo / Inactivo
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? Colors.green.withAlpha(25)
                                  : Colors.grey.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user.isActive
                                    ? Colors.green.withAlpha(80)
                                    : Colors.grey.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isActive
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  size: 12,
                                  color: user.isActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isActive ? 'Activo' : 'Inactivo',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: user.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Contacto
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (user.email != null && user.email!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 15,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.email!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 15,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.phone!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Sedes autorizadas
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sedes: ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: user.branches.map((bId) {
                                final branchName =
                                    branchesMap[bId] ?? 'Sede ($bId)';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    branchName,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Acciones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Editar Usuario',
                      onPressed: () => onEdit(user),
                    ),
                    if (!user.isInternal && user.id != 'root' && user.username != 'Serum')
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'Eliminar Usuario',
                        onPressed: () => _confirmDelete(context, user),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
