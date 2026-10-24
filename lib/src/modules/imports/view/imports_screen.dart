import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/imports_cubit/imports_cubit.dart';
import '../../../cubits/imports_cubit/imports_state.dart';
import '../../../widgets/gates/permission_gate.dart';
import '../widgets/branch_prices_import_card.dart';

class ImportsScreen extends StatelessWidget {
  const ImportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<ImportsRepository>(context);

    return BlocProvider(
      create: (context) => ImportsCubit(importsRepository: repo),
      child: const _ImportsScaffold(),
    );
  }
}

class _ImportsScaffold extends StatelessWidget {
  const _ImportsScaffold();

  void _confirmAndExecuteImport(BuildContext context) {
    final cubit = context.read<ImportsCubit>();

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.blue),
            SizedBox(width: 12),
            Text('Confirmar Importación'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas ejecutar la importación del catálogo clínico maestro?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              'Este proceso registrará las pruebas clínicas de rutina, paquetes diagnósticos (perfiles) y cuentas contables por defecto. Las pruebas ya existentes serán conservadas.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.cloud_download_rounded, size: 18),
            label: const Text('Iniciar Importación'),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        cubit.importDefaultCatalog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header Bar institucional
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
                IconButton.filledTonal(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver a Administración',
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.cloud_download_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importaciones del Sistema',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Carga e inicialización de catálogos maestros, datos base y sincronización multi-sede',
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

          // Main Body
          Expanded(
            child: PermissionGate(
              level: AccessLevels.supervisor,
              builder: (context, hasPermission) {
                if (!hasPermission) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.errorContainer.withAlpha(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.error.withAlpha(100),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Acceso Restringido',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Se requieren permisos de Administrador o Supervisor (Nivel 4+) para acceder al módulo de importaciones del sistema.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return BlocConsumer<ImportsCubit, ImportsState>(
                  listener: (context, state) {
                    if (state is ImportsSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.result.message),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is ImportsPricesSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.result.message),
                          backgroundColor: Colors.teal.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state is ImportsFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${state.message}'),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    final isLoading = state is ImportsLoading;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Tarjeta principal: Catálogo Clínico por Defecto
                              _buildDefaultCatalogCard(
                                context,
                                theme: theme,
                                isLoading: isLoading,
                                onImport: () => _confirmAndExecuteImport(context),
                              ),

                              const SizedBox(height: 24),

                              // 2. Tarjeta: Importación de Precios entre Sucursales
                              BranchPricesImportCard(
                                isLoading: isLoading,
                              ),

                              const SizedBox(height: 24),

                              // 3. Estado de carga en progreso
                              if (isLoading)
                                _buildLoadingIndicator(context, theme, state),

                              // 4. Tarjetas de Resultados (KPIs)
                              if (state is ImportsSuccess)
                                _buildResultsCard(context, theme, state.result),

                              if (state is ImportsPricesSuccess)
                                _buildPricesResultsCard(
                                    context, theme, state.result),

                              // 5. Tarjeta de Error
                              if (state is ImportsFailure)
                                _buildErrorCard(context, theme, state.message),

                              const SizedBox(height: 32),

                              // 6. Próximas importaciones (Roadmap extensible)
                              _buildUpcomingImportsSection(context, theme),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCatalogCard(
    BuildContext context, {
    required ThemeData theme,
    required bool isLoading,
    required VoidCallback onImport,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.biotech_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Catálogo Clínico Maestro por Defecto',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withAlpha(120),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Oficial Serum LIS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Inicializa o sincroniza la base de datos con el catálogo estandarizado de pruebas clínicas, rangos de referencia, perfiles de diagnóstico y cuentas de catálogo.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Elementos incluidos
            Text(
              'Contenido del paquete de importación:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildFeatureChip(
                  theme,
                  Icons.science_outlined,
                  'Química Clínica (Glucosa, Creatinina, Perfil Hepático...)',
                ),
                _buildFeatureChip(
                  theme,
                  Icons.bloodtype_outlined,
                  'Hematología Completa (BHC con Índices de Wintrobe)',
                ),
                _buildFeatureChip(
                  theme,
                  Icons.water_drop_outlined,
                  'Urianálisis y Coprología Completa',
                ),
                _buildFeatureChip(
                  theme,
                  Icons.layers_outlined,
                  'Packs y Perfiles (Perfil Lipídico, Baterías Diagnósticas)',
                ),
                _buildFeatureChip(
                  theme,
                  Icons.account_tree_outlined,
                  'Cuentas Comerciales de Laboratorio inicializadas',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Advertencia de conservación de datos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Operación segura e idempotente: Las pruebas ya existentes no serán sobrescritas ni se duplicarán registros.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón de Acción
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_download_rounded, size: 18),
                label: Text(
                  isLoading ? 'Procesando...' : 'Iniciar Importación de Catálogo',
                ),
                onPressed: isLoading ? null : onImport,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(
    BuildContext context,
    ThemeData theme,
    ImportsLoading state,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proceso de Importación en Curso...',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.message ??
                        'Sincronizando información en la base de datos...',
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
    );
  }

  Widget _buildResultsCard(
    BuildContext context,
    ThemeData theme,
    ImportCatalogResult result,
  ) {
    return Card(
      elevation: 0,
      color: Colors.green.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado de la Importación',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        result.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Cerrar resumen',
                  onPressed: () => context.read<ImportsCubit>().reset(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Métricas KPIs en cuadrícula
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildKpiCard(
                      theme,
                      title: 'Total Procesadas',
                      value: result.totalProcessed.toString(),
                      icon: Icons.inventory_rounded,
                      color: Colors.blue,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Pruebas Creadas',
                      value: result.atomicCreated.toString(),
                      icon: Icons.science_rounded,
                      color: Colors.green,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Packs / Perfiles',
                      value: result.packsCreated.toString(),
                      icon: Icons.layers_rounded,
                      color: Colors.purple,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Cuentas Creadas',
                      value: result.accountsCreated.toString(),
                      icon: Icons.account_tree_rounded,
                      color: Colors.amber.shade800,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Ya Existentes',
                      value: result.alreadyExisting.toString(),
                      icon: Icons.verified_rounded,
                      color: Colors.teal,
                      width: isCompact ? double.infinity : 170,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricesResultsCard(
    BuildContext context,
    ThemeData theme,
    ImportBranchPricesResult result,
  ) {
    return Card(
      elevation: 0,
      color: Colors.teal.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Resultado de Importación de Precios',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Cerrar resumen',
                            onPressed: () =>
                                context.read<ImportsCubit>().reset(),
                          ),
                        ],
                      ),
                      Text(
                        result.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(70),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    result.mustOverridePrice
                        ? Icons.edit_note_rounded
                        : Icons.add_task_rounded,
                    size: 16,
                    color: result.mustOverridePrice
                        ? Colors.amber.shade900
                        : Colors.blue.shade800,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Modo: ${result.mustOverridePrice ? 'Sobreescritura total' : 'Actualización en \$0'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: result.mustOverridePrice
                          ? Colors.amber.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${result.sourceBranchName.isNotEmpty ? result.sourceBranchName : result.sourceBranchId} ➔ ${result.targetBranchName.isNotEmpty ? result.targetBranchName : result.targetBranchId}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Métricas KPIs en cuadrícula
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildKpiCard(
                      theme,
                      title: 'Pruebas Evaluadas',
                      value: result.totalEvaluated.toString(),
                      icon: Icons.playlist_add_check_rounded,
                      color: Colors.blue,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Precios Actualizados',
                      value: result.updatedCount.toString(),
                      icon: Icons.update_rounded,
                      color: Colors.teal,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Cuentas Creadas',
                      value: result.createdCount.toString(),
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green,
                      width: isCompact ? double.infinity : 170,
                    ),
                    _buildKpiCard(
                      theme,
                      title: 'Omitidas / Sin cambio',
                      value: result.skippedCount.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.blueGrey,
                      width: isCompact ? double.infinity : 170,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ThemeData theme, String error) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer.withAlpha(50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.error.withAlpha(100)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error al procesar la importación',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingImportsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Otras Fuentes de Importación',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Módulos adicionales en desarrollo para la migración de datos masivos:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUpcomingCard(
                theme,
                title: 'Importación Excel / CSV de Pacientes',
                description:
                    'Carga masiva de historiales demográficos y contactos desde hojas de cálculo.',
                icon: Icons.people_outline_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUpcomingCard(
                theme,
                title: 'Importación de Médicos Referentes',
                description:
                    'Directorio de médicos, números de colegiatura y convenios clínicos.',
                icon: Icons.local_hospital_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(
    ThemeData theme, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.outline, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Próximamente',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
