import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/report_cubit/report_cubit.dart';
import '../../../cubits/report_cubit/report_state.dart';
import '../../../widgets/gates/permission_gate.dart';
import '../widgets/financial_report_view.dart';
import '../widgets/lab_tests_volume_view.dart';
import '../widgets/pending_balances_view.dart';
import '../widgets/reports_filter_bar.dart';
import '../widgets/shifts_audit_view.dart';
import '../widgets/top_doctors_report_view.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentBranchId = context.read<AppSessionCubit>().currentBranchId;
    final userLevel = context.userAccessLevel;
    final initialTab = userLevel >= AccessLevels.supervisor
        ? ReportTab.financial
        : ReportTab.labTestsVolume;

    return BlocProvider(
      create: (context) {
        final cubit = ReportCubit(
          reportsRepository: context.read<ReportsRepository>(),
          initialBranchId: currentBranchId,
        );
        if (initialTab != ReportTab.financial) {
          cubit.changeTab(initialTab);
        } else {
          cubit.loadActiveReport();
        }
        return cubit;
      },
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = context.watch<ReportCubit>().state;
    final reportCubit = context.read<ReportCubit>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportes & Métricas Analíticas',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inteligencia de negocio, control de demanda y auditoría de flujo clínico.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de Filtros (Fechas y Sucursal)
              const ReportsFilterBar(),
              const SizedBox(height: 16),

              // Pestañas / Segmentos de Reportes
              _buildTabsBar(context, reportState, reportCubit, theme),
              const SizedBox(height: 12),

              // Contenido Principal
              Expanded(
                child: _buildBody(context, reportState, reportCubit, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsBar(
    BuildContext context,
    ReportState state,
    ReportCubit cubit,
    ThemeData theme,
  ) {
    final hasSupervisorAccess =
        context.hasAccessLevel(AccessLevels.supervisor);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabItem(
            icon: Icons.monetization_on_outlined,
            title: 'Financiero',
            isRestricted: !hasSupervisorAccess,
            isSelected: state.activeTab == ReportTab.financial,
            onTap: () => cubit.changeTab(ReportTab.financial),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.medical_services_outlined,
            title: 'Top Médicos',
            isSelected: state.activeTab == ReportTab.topDoctors,
            onTap: () => cubit.changeTab(ReportTab.topDoctors),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.science_outlined,
            title: 'Volumen de Exámenes',
            isSelected: state.activeTab == ReportTab.labTestsVolume,
            onTap: () => cubit.changeTab(ReportTab.labTestsVolume),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.pending_actions_outlined,
            title: 'Cuentas por Cobrar',
            isSelected: state.activeTab == ReportTab.pendingBalances,
            onTap: () => cubit.changeTab(ReportTab.pendingBalances),
          ),
          const SizedBox(width: 8),
          _TabItem(
            icon: Icons.security_outlined,
            title: 'Auditoría de Turnos',
            isRestricted: !hasSupervisorAccess,
            isSelected: state.activeTab == ReportTab.shiftsAudit,
            onTap: () => cubit.changeTab(ReportTab.shiftsAudit),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReportState state,
    ReportCubit cubit,
    ThemeData theme,
  ) {
    if (state.status == ReportStatus.loading && !_hasDataForTab(state)) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.status == ReportStatus.error && !_hasDataForTab(state)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: ColorPalette.error),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Ocurrió un error al cargar el reporte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => cubit.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    // Renderizar vista según la pestaña activa
    switch (state.activeTab) {
      case ReportTab.financial:
        return PermissionGate(
          level: AccessLevels.supervisor,
          builder: (context, hasPermission) {
            if (!hasPermission) {
              return const _RestrictedAccessPlaceholder(
                moduleName: 'Reporte Financiero',
              );
            }
            if (state.financialReport == null) {
              return const Center(child: Text('Sin información disponible.'));
            }
            return FinancialReportView(report: state.financialReport!);
          },
        );

      case ReportTab.topDoctors:
        if (state.topDoctorsReport == null) {
          return const Center(child: Text('Sin información disponible.'));
        }
        return TopDoctorsReportView(report: state.topDoctorsReport!);

      case ReportTab.labTestsVolume:
        if (state.labTestsVolumeReport == null) {
          return const Center(child: Text('Sin información disponible.'));
        }
        return LabTestsVolumeView(report: state.labTestsVolumeReport!);

      case ReportTab.pendingBalances:
        if (state.pendingBalancesReport == null) {
          return const Center(child: Text('Sin información disponible.'));
        }
        return PendingBalancesView(report: state.pendingBalancesReport!);

      case ReportTab.shiftsAudit:
        return PermissionGate(
          level: AccessLevels.supervisor,
          builder: (context, hasPermission) {
            if (!hasPermission) {
              return const _RestrictedAccessPlaceholder(
                moduleName: 'Auditoría de Turnos y Arqueos',
              );
            }
            if (state.shiftsAuditReport == null) {
              return const Center(child: Text('Sin información disponible.'));
            }
            return ShiftsAuditView(report: state.shiftsAuditReport!);
          },
        );
    }
  }

  bool _hasDataForTab(ReportState state) {
    switch (state.activeTab) {
      case ReportTab.financial:
        return state.financialReport != null;
      case ReportTab.topDoctors:
        return state.topDoctorsReport != null;
      case ReportTab.labTestsVolume:
        return state.labTestsVolumeReport != null;
      case ReportTab.pendingBalances:
        return state.pendingBalancesReport != null;
      case ReportTab.shiftsAudit:
        return state.shiftsAuditReport != null;
    }
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isRestricted;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    this.isRestricted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primary
                : theme.colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (isRestricted) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: isSelected ? Colors.white70 : theme.colorScheme.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestrictedAccessPlaceholder extends StatelessWidget {
  final String moduleName;

  const _RestrictedAccessPlaceholder({required this.moduleName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorPalette.tertiaryContainer.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_outlined,
                size: 48,
                color: ColorPalette.tertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acceso Restringido: $moduleName',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Se requiere rol de Supervisor o Administrador (Nivel 4 o superior) para acceder a métricas financieras confidenciales y auditorías de arqueo de caja.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
