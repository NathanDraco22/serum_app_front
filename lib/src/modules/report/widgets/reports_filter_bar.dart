import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/report_cubit/report_cubit.dart';

class ReportsFilterBar extends StatelessWidget {
  const ReportsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportState = context.watch<ReportCubit>().state;
    final reportCubit = context.read<ReportCubit>();
    final sessionBranches = context.watch<AppSessionCubit>().branches;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final startStr = dateFormat.format(reportState.startDate);
    final endStr = dateFormat.format(reportState.endDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Selector de Fechas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final initialRange = DateTimeRange(
                    start: reportState.startDate,
                    end: reportState.endDate,
                  );
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2025),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: initialRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: ColorPalette.primary,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    reportCubit.setDateRange(picked.start, picked.end);
                  }
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  '$startStr - $endStr',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Botones de presets
              _PresetButton(
                label: 'Hoy',
                onPressed: () {
                  final now = DateTime.now();
                  reportCubit.setDateRange(now, now);
                },
              ),
              _PresetButton(
                label: '7 días',
                onPressed: () {
                  final now = DateTime.now();
                  final weekAgo = now.subtract(const Duration(days: 6));
                  reportCubit.setDateRange(weekAgo, now);
                },
              ),
              _PresetButton(
                label: 'Este mes',
                onPressed: () {
                  final now = DateTime.now();
                  final startOfMonth = DateTime(now.year, now.month, 1);
                  reportCubit.setDateRange(startOfMonth, now);
                },
              ),
            ],
          ),

          // Selector de Sucursal y botón de refresco
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (sessionBranches.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withAlpha(90),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: reportState.branchId,
                      hint: const Text('Todas las sucursales'),
                      icon: const Icon(Icons.store, size: 18),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      onChanged: (newBranchId) {
                        reportCubit.setBranchId(newBranchId);
                      },
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('🏢 Todas las sucursales'),
                        ),
                        ...sessionBranches.map(
                          (branch) => DropdownMenuItem<String?>(
                            value: branch.id,
                            child: Text(branch.name),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton.filledTonal(
                tooltip: 'Recargar reporte',
                icon: reportState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                onPressed: reportState.isLoading ? null : () => reportCubit.refresh(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PresetButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label),
    );
  }
}
