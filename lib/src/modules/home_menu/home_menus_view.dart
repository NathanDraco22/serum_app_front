import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:serum_business/serum_business.dart';

import '../../../config/app_assets.dart';
import '../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../widgets/common/app_cached_image.dart';
import '../../widgets/dialogs/selectors/branch_selection_dialog.dart';
import '../../widgets/dialogs/viewers/cash_shift_viewer.dart';
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
    _NavItemData(icon: Icons.lock_clock_outlined, label: 'Turnos de Caja'),
    _NavItemData(icon: Icons.receipt, label: 'Recibos de Caja'),
    _NavItemData(icon: Icons.analytics_outlined, label: 'Reportes'),
    _NavItemData(icon: Icons.admin_panel_settings, label: 'Administración'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIndex = navigationShell.currentIndex;
    final sessionCubit = context.watch<AppSessionCubit>();
    final sessionState = sessionCubit.state;
    final user = sessionState.currentUser;
    final activeShift = sessionState.activeShift;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: 260,
        child: Column(
          children: [
            // Logo / Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  _buildSidebarLogo(context, sessionState.currentBranch),
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
                                sessionState.currentBranch?.displayName ?? 'Sin sucursal',
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
                        if (sessionCubit.hasMultipleBranches)
                          IconButton(
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            tooltip: 'Cambiar Sucursal',
                            onPressed: () async {
                              if (sessionCubit.isRootUser) {
                                await sessionCubit.refreshBranches();
                              }
                              if (!context.mounted) return;
                              final filteredBranches = sessionCubit.branches
                                  .where((b) => b.id != sessionCubit.currentBranchId)
                                  .toList();
                              final res = await showBranchSelectionDialog(
                                context,
                                filteredBranches,
                              );
                              if (res == null) return;
                              if (!context.mounted) return;
                              await sessionCubit.changeBranch(res.id);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Active Cash Shift info
                  Builder(
                    builder: (context) {
                      final hasMismatch = sessionState.hasShiftBranchMismatch;
                      final isInBranch = sessionState.isShiftInCurrentBranch;

                      Color bgColor;
                      Color borderColor;
                      IconData iconData;
                      Color iconColor;
                      String titleText;
                      String subtitleText;
                      Color titleColor;
                      Color subtitleColor;
                      Widget actionButton;

                      if (activeShift != null && hasMismatch) {
                        bgColor = Colors.amber.shade50;
                        borderColor = Colors.amber.shade400;
                        iconData = Icons.warning_amber_rounded;
                        iconColor = Colors.amber.shade900;
                        titleText =
                            'Turno en "${sessionCubit.displayNameForBranch(activeShift.branchId, fallbackName: activeShift.branchName)}"';
                        subtitleText =
                            '${NumberFormatter.currencyFormat.format(activeShift.totalCashExpectedDouble)} • Cambia de sucursal';
                        titleColor = Colors.amber.shade900;
                        subtitleColor = Colors.amber.shade800;
                        actionButton = IconButton(
                          icon: Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: Colors.amber.shade900,
                          ),
                          tooltip:
                              'Cambiar a ${sessionCubit.displayNameForBranch(activeShift.branchId, fallbackName: activeShift.branchName)}',
                          onPressed: () {
                            context.read<AppSessionCubit>().changeBranch(activeShift.branchId);
                          },
                        );
                      } else if (activeShift != null && isInBranch) {
                        bgColor = theme.colorScheme.primaryContainer.withAlpha(50);
                        borderColor = theme.colorScheme.primary.withAlpha(80);
                        iconData = Icons.point_of_sale;
                        iconColor = theme.colorScheme.primary;
                        titleText =
                            '${NumberFormatter.currencyFormat.format(activeShift.totalCashExpectedDouble)} en caja';
                        subtitleText =
                            'Turno Activo (Fondo: ${NumberFormatter.currencyFormat.format(activeShift.initialBalanceDouble)})';
                        titleColor = theme.colorScheme.onSurface;
                        subtitleColor = theme.colorScheme.onSurfaceVariant;
                        actionButton = IconButton(
                          icon: Icon(
                            Icons.lock_clock_rounded,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Corte y Arqueo de Turno',
                          onPressed: () async {
                            final res = await CashShiftCloseDialog.show(context, activeShift);
                            if (res != null && context.mounted) {
                              showCashShiftViewerDialog(context, res);
                            }
                          },
                        );
                      } else {
                        bgColor = theme.colorScheme.surfaceContainerHighest.withAlpha(40);
                        borderColor = theme.colorScheme.outlineVariant.withAlpha(80);
                        iconData = Icons.lock_open_rounded;
                        iconColor = theme.colorScheme.onSurfaceVariant;
                        titleText = 'Sin turno abierto';
                        subtitleText = 'Abre turno para cobrar';
                        titleColor = theme.colorScheme.onSurface;
                        subtitleColor = theme.colorScheme.onSurfaceVariant;
                        actionButton = IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Abrir Turno de Caja',
                          onPressed: () {
                            CashShiftOpenDialog.show(context);
                          },
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              iconData,
                              size: 18,
                              color: iconColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    subtitleText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: subtitleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            actionButton,
                          ],
                        ),
                      );
                    },
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
      ),
    );
  }

  Widget _buildSidebarLogo(BuildContext context, BranchInDb? currentBranch) {
    final theme = Theme.of(context);
    final logoUrl = currentBranch?.effectiveLogo;

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4),
        child: AppCachedImage(
          imageUrl: logoUrl,
          fit: BoxFit.contain,
          fallbackWidget: _buildFallbackAssetLogo(theme),
        ),
      );
    }

    return _buildFallbackAssetLogo(theme);
  }

  Widget _buildFallbackAssetLogo(ThemeData theme) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        AppAssets.serumLogo,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.biotech,
          color: theme.colorScheme.primary,
          size: 26,
        ),
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
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
    );
  }
}
