import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/get_it_config.dart';
import '../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../widgets/dialogs/selectors/branch_selection_dialog.dart';
import '../cash_shift/widgets/cash_shift_open_dialog.dart';
import '../cash_shift/widgets/cash_shift_close_dialog.dart';

class HomeMenusScreen extends StatelessWidget {
  const HomeMenusScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menú lateral
          _SideNav(navigationShell: navigationShell),
          const VerticalDivider(width: 1),
          // Contenido del shell branch
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Menú lateral ───────────────────────────────────────────────────────

class _SideNav extends StatelessWidget {
  const _SideNav({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavItemData>[
    _NavItemData(icon: Icons.dashboard, label: 'Inicio'),
    _NavItemData(icon: Icons.people, label: 'Pacientes'),
    _NavItemData(icon: Icons.badge, label: 'Médicos'),
    _NavItemData(icon: Icons.science, label: 'Pruebas de Lab.'),
    _NavItemData(icon: Icons.receipt_long, label: 'Órdenes Clínicas'),
    _NavItemData(icon: Icons.request_quote, label: 'Cotizaciones'),
    _NavItemData(icon: Icons.point_of_sale, label: 'Cajas Registradoras'),
    _NavItemData(icon: Icons.payments, label: 'Transacciones de Caja'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;
    final sessionState = context.watch<AppSessionCubit>().state;
    final user = sessionState.currentUser;
    final activeShift = sessionState.activeShift;

    return Container(
      width: 260,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Logo / Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Icon(Icons.biotech),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serum LIS',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Sistema de Laboratorio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _NavItem(
                  icon: item.icon,
                  label: item.label,
                  isSelected: currentIndex == index,
                  onTap: () => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // Footer / Sucursal, Caja & Sesión
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Branch Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.secondaryContainer,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sessionState.currentBranch?.name ?? 'Sin sucursal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sucursal Activa',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (context.read<AppSessionCubit>().hasMultipleBranches)
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          tooltip: 'Cambiar Sucursal',
                          onPressed: () async {
                            final authCubit = getIt<AppSessionCubit>();
                            final filteredBranches = authCubit.branches
                                .where((b) => b.id != authCubit.currentBranchId)
                                .toList();
                            final res = await showBranchSelectionDialog(
                              context,
                              filteredBranches,
                            );
                            if (res == null) return;
                            if (!context.mounted) return;
                            await authCubit.changeBranch(res.id);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Active Cash Shift info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: activeShift != null
                        ? theme.colorScheme.primaryContainer.withAlpha(50)
                        : theme.colorScheme.surfaceContainerHighest.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: activeShift != null
                          ? theme.colorScheme.primary.withAlpha(80)
                          : theme.colorScheme.outlineVariant.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activeShift != null
                            ? Icons.point_of_sale
                            : Icons.lock_open_rounded,
                        size: 18,
                        color: activeShift != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeShift != null
                                  ? '\$${activeShift.totalCashExpectedDouble.toStringAsFixed(2)} en caja'
                                  : 'Sin turno abierto',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              activeShift != null
                                  ? 'Turno Activo (Fondo: \$${activeShift.initialBalanceDouble.toStringAsFixed(2)})'
                                  : 'Abre turno para cobrar',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          activeShift != null
                              ? Icons.lock_clock_rounded
                              : Icons.add_circle_outline,
                          size: 18,
                          color: activeShift != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        tooltip: activeShift != null
                            ? 'Corte y Arqueo de Turno'
                            : 'Abrir Turno de Caja',
                        onPressed: () {
                          if (activeShift != null) {
                            CashShiftCloseDialog.show(context, activeShift);
                          } else {
                            CashShiftOpenDialog.show(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // User Info & Logout
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      radius: 16,
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name.substring(0, 1).toUpperCase()
                            : 'U',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? user?.username ?? 'Usuario',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.role.toUpperCase() ?? 'SESIÓN ACTIVA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, size: 18),
                      tooltip: 'Cerrar Sesión',
                      onPressed: () {
                        context.read<AppSessionCubit>().logout();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Widget ────────────────────────────────────────────────────

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          title: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: onTap,
          dense: true,
        ),
      ),
    );
  }
}
