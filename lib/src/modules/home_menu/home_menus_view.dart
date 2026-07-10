import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    _NavItemData(icon: Icons.assignment_outlined, label: 'Exámenes'),
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
          // Footer / Session Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  radius: 16,
                  child: const Text('AD'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrador',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sesión Activa',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
