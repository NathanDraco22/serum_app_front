import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/report_cubit/report_cubit.dart';

class ShiftsAuditView extends StatelessWidget {
  final ShiftsAuditReportResponse report;

  const ShiftsAuditView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportCubit = context.read<ReportCubit>();
    final reportState = context.watch<ReportCubit>().state;
    final summary = report.summary;

    // Recopilar todos los turnos de todas las sucursales
    final allShifts = <ShiftAuditItem>[];
    for (final b in report.byBranch) {
      allShifts.addAll(b.shifts);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector y Filtro de Discrepancias
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arqueos y Cierres de Turnos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilterChip(
                label: const Text('Solo con discrepancias (faltante/sobrante)'),
                selected: reportState.onlyDiscrepancies,
                avatar: const Icon(Icons.filter_list, size: 16),
                onSelected: (val) {
                  reportCubit.setOnlyDiscrepancies(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tarjetas KPI de Auditoría
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _AuditKpiCard(
                title: 'Turnos Auditados',
                value: summary.totalShifts.toString(),
                subtitle: 'Sesiones de caja evaluadas',
                icon: Icons.lock_clock,
                color: ColorPalette.primary,
              ),
              _AuditKpiCard(
                title: 'Turnos con Discrepancia',
                value: summary.totalDiscrepancies.toString(),
                subtitle: 'Descuadres detectados',
                icon: Icons.warning_amber_rounded,
                color: summary.totalDiscrepancies > 0
                    ? ColorPalette.error
                    : const Color(0xFF2E7D32),
              ),
              _AuditKpiCard(
                title: 'Diferencia Neta Acumulada',
                value: NumberFormatter.convertToMoneyLike(summary.netDifference),
                subtitle: summary.netDifference == 0
                    ? 'Arqueo perfecto'
                    : (summary.netDifference > 0
                        ? 'Sobrante acumulado'
                        : 'Faltante acumulado'),
                icon: summary.netDifference >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: summary.netDifference == 0
                    ? const Color(0xFF2E7D32)
                    : (summary.netDifference > 0
                        ? const Color(0xFF2E7D32)
                        : ColorPalette.error),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (allShifts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.done_all,
                      size: 48,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron turnos bajo los filtros seleccionados.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Gráfico de Diferencias ($)
            _buildDifferencesChart(theme, allShifts),
            const SizedBox(height: 24),

            // Tabla detallada de Auditoría
            _buildShiftsTable(theme, allShifts),
          ],
        ],
      ),
    );
  }

  Widget _buildDifferencesChart(ThemeData theme, List<ShiftAuditItem> shifts) {
    // Tomar hasta los últimos 10 turnos para el gráfico
    final chartShifts = shifts.take(10).toList();

    double maxVal = 0.0;
    double minVal = 0.0;

    for (final s in chartShifts) {
      final diff = (s.difference ?? 0) / 100;
      if (diff > maxVal) maxVal = diff;
      if (diff < minVal) minVal = diff;
    }

    final double effectiveMax = maxVal > 0 ? maxVal * 1.3 : 10.0;
    final double effectiveMin = minVal < 0 ? minVal * 1.3 : -10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Diferencias de Efectivo por Turno (\$)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Leyendas
              Row(
                children: [
                  Container(width: 10, height: 10, color: const Color(0xFF2E7D32)),
                  const SizedBox(width: 4),
                  const Text('Sobrante', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, color: ColorPalette.error),
                  const SizedBox(width: 4),
                  const Text('Faltante', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 12),
                  Container(width: 10, height: 10, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  const Text('Cuadrado (\$0)', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Desviación entre el efectivo físico declarado y el saldo registrado por el sistema.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: effectiveMin,
                maxY: effectiveMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => ColorPalette.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = chartShifts[group.x.toInt()];
                      final diff = item.difference ?? 0;
                      return BarTooltipItem(
                        '${item.userName.isEmpty ? 'Cajero' : item.userName}\n${NumberFormatter.convertToMoneyLike(diff)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < chartShifts.length) {
                          final shift = chartShifts[idx];
                          final label = shift.userName.isNotEmpty
                              ? shift.userName.split(' ').first
                              : '#${shift.shiftId.substring(math.max(0, shift.shiftId.length - 4))}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == 0
                        ? theme.colorScheme.outline.withAlpha(120)
                        : theme.colorScheme.outlineVariant.withAlpha(40),
                    strokeWidth: value == 0 ? 1.5 : 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartShifts.length, (idx) {
                  final shift = chartShifts[idx];
                  final diffCents = shift.difference ?? 0;
                  final diffDouble = diffCents / 100;

                  Color barColor;
                  if (diffCents > 0) {
                    barColor = const Color(0xFF2E7D32);
                  } else if (diffCents < 0) {
                    barColor = ColorPalette.error;
                  } else {
                    barColor = theme.colorScheme.outlineVariant;
                  }

                  // Si es 0, dibujamos una pequeña barra visible de altura mínima
                  final toY = diffDouble == 0 ? 0.5 : diffDouble;

                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: toY,
                        color: barColor,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftsTable(ThemeData theme, List<ShiftAuditItem> shifts) {
    final dateFormat = DateFormat('dd/MM/yy HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_view, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Detalle de Auditoría de Cierres de Caja',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerLow,
              ),
              columns: const [
                DataColumn(label: Text('Turno', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cajero', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Apertura', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cierre', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Saldo Sistema', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Efectivo Declarado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Diferencia', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Notas / Observaciones', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: shifts.map((s) {
                final openStr = dateFormat.format(
                  DateTime.fromMillisecondsSinceEpoch(s.openedAt),
                );
                final closeStr = s.closedAt != null
                    ? dateFormat.format(
                        DateTime.fromMillisecondsSinceEpoch(s.closedAt!),
                      )
                    : 'Abierto';

                final diff = s.difference ?? 0;
                final isSquare = diff == 0;
                final isSurplus = diff > 0;

                return DataRow(
                  cells: [
                    DataCell(Text(
                      '#${s.shiftId.substring(math.max(0, s.shiftId.length - 6))}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    DataCell(Text(
                      s.userName.isEmpty ? 'Usuario' : s.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(openStr)),
                    DataCell(Text(closeStr)),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(s.cashBalance))),
                    DataCell(Text(
                      s.declaredCash != null
                          ? NumberFormatter.convertToMoneyLike(s.declaredCash!)
                          : '—',
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSquare
                              ? theme.colorScheme.surfaceContainerHigh
                              : (isSurplus
                                  ? const Color(0xFFE8F5E9)
                                  : ColorPalette.errorContainer),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          NumberFormatter.convertToMoneyLike(diff),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSquare
                                ? theme.colorScheme.onSurface
                                : (isSurplus
                                    ? const Color(0xFF2E7D32)
                                    : ColorPalette.error),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(s.notes.isEmpty ? '—' : s.notes)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AuditKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(70),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
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
