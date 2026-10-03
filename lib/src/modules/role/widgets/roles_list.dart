import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/role_cubit/write_roles_cubit.dart';

class RolesList extends StatelessWidget {
  const RolesList({
    super.key,
    required this.roles,
    required this.onEdit,
  });

  final List<RoleInDb> roles;
  final void Function(RoleInDb role) onEdit;

  void _confirmDelete(BuildContext context, RoleInDb role) {
    final theme = Theme.of(context);
    final writeCubit = context.read<WriteRoleCubit>();

    if (role.name.toLowerCase() == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El rol principal "Admin" no puede ser eliminado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            const Text('Eliminar Rol'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el rol "${role.name}"?\nEsta acción no se puede deshacer.',
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
              writeCubit.delete(role.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(int level, ColorScheme colors) {
    switch (level) {
      case 5:
        return Colors.deepPurple;
      case 4:
        return Colors.indigo;
      case 3:
        return colors.primary;
      case 2:
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 5:
        return 'Nivel 5 — Administrador (Acceso Total)';
      case 4:
        return 'Nivel 4 — Supervisor / Auditoría';
      case 3:
        return 'Nivel 3 — Operador (POS y Laboratorio)';
      case 2:
        return 'Nivel 2 — Asistente / Recepción';
      default:
        return 'Nivel 1 — Consulta Básica';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withAlpha(120),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron roles',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un nuevo rol o ajusta los criterios de búsqueda.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant.withAlpha(180),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 460,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.55,
          ),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            final levelColor = _getLevelColor(role.accessLevel, colors);
            final isAdmin = role.name.toLowerCase() == 'admin';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colors.outlineVariant.withAlpha(100),
                ),
              ),
              color: colors.surfaceContainerLowest,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Role Name and Access Level Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: levelColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.security_rounded,
                            color: levelColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: levelColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: levelColor.withAlpha(70),
                                  ),
                                ),
                                child: Text(
                                  _getLevelTitle(role.accessLevel),
                                  style: TextStyle(
                                    color: levelColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Expanded(
                      child: Text(
                        role.description?.isNotEmpty == true
                            ? role.description!
                            : 'Sin descripción asignada para este rol operativo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Divider(height: 16),

                    // Footer actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => onEdit(role),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Editar'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (!isAdmin) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context, role),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: colors.error,
                            ),
                            label: Text(
                              'Eliminar',
                              style: TextStyle(color: colors.error),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
