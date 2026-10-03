import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_router.dart';
import '../widgets/admin_module_card.dart';

class AdministrationScreen extends StatelessWidget {
  const AdministrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administración del Sistema',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configuración global de infraestructura, sedes clínicas y personal autorizado',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Grid Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Módulos de Configuración',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona un módulo para abrir su consola de gestión en pantalla completa.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.extent(
                        maxCrossAxisExtent: 420,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.45,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // 1. Sucursales / Ramas
                          AdminModuleCard(
                            title: 'Sucursales / Sedes',
                            description:
                                'Alta, modificación y control de sedes físicas, direcciones de atención clínica y teléfonos de contacto.',
                            icon: Icons.store_mall_directory_rounded,
                            iconColor: theme.colorScheme.primary,
                            iconBackgroundColor:
                                theme.colorScheme.primaryContainer.withAlpha(90),
                            badgeText: 'Sedes Físicas',
                            onTap: () => context.push(AppRouter.adminBranches),
                          ),

                          // 2. Usuarios
                          AdminModuleCard(
                            title: 'Usuarios y Accesos',
                            description:
                                'Gestión de cuentas de personal, credenciales, asignación de roles operativos y sedes autorizadas para cada usuario.',
                            icon: Icons.manage_accounts_rounded,
                            iconColor: theme.colorScheme.secondary,
                            iconBackgroundColor:
                                theme.colorScheme.secondaryContainer.withAlpha(90),
                            badgeText: 'Personal',
                            onTap: () => context.push(AppRouter.adminUsers),
                          ),

                          // 3. Roles y Niveles de Acceso
                          AdminModuleCard(
                            title: 'Roles y Niveles de Acceso',
                            description:
                                'Configuración de perfiles y jerarquía de permisos del sistema (Niveles 1 al 5: Admin, Operador, etc.).',
                            icon: Icons.security_rounded,
                            iconColor: theme.colorScheme.tertiary,
                            iconBackgroundColor:
                                theme.colorScheme.tertiaryContainer.withAlpha(90),
                            badgeText: 'Jerarquía',
                            onTap: () => context.push(AppRouter.adminRoles),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
