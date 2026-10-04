import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';

class TopDoctorsReportView extends StatelessWidget {
  final TopDoctorsReportResponse report;

  const TopDoctorsReportView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = report.summary;
    final topDoctors = summary.topDoctors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen rápido en tarjetas
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _DoctorKpiCard(
                title: 'Médicos Activos',
                value: topDoctors.length.toString(),
                subtitle: 'Con derivación en el período',
                icon: Icons.badge,
                color: ColorPalette.primary,
              ),
              _DoctorKpiCard(
                title: 'Total de Órdenes Derivadas',
                value: summary.totalOrders.toString(),
                subtitle: 'Órdenes con médico asignado',
                icon: Icons.assignment_ind,
                color: ColorPalette.secondary,
              ),
              _DoctorKpiCard(
                title: 'Ingresos por Derivaciones',
                value: NumberFormatter.convertToMoneyLike(summary.totalRevenue),
                subtitle: 'Facturación de órdenes con médico',
                icon: Icons.monetization_on,
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (topDoctors.isEmpty)
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
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay datos de médicos prescriptores en este rango.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Gráfico BarChart de Top 5 o Top 10 Médicos
            _buildChartCard(theme, topDoctors),
            const SizedBox(height: 24),

            // Tabla de Detalle
            _buildDoctorsTable(theme, topDoctors),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, List<DoctorOrderItem> doctors) {
    // Tomar los primeros 5 o 7 para el gráfico para que no se amontone
    final chartItems = doctors.take(7).toList();
    final maxRevenue = chartItems.isEmpty
        ? 100.0
        : chartItems
            .map((d) => d.totalRevenue / 100)
            .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRevenue > 0 ? maxRevenue * 1.2 : 100.0;

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
              Icon(Icons.leaderboard, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Top Médicos por Facturación Generada',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresos totales generados por los médicos con mayor prescripción clínica.',
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
                maxY: effectiveMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => ColorPalette.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final doc = chartItems[group.x.toInt()];
                      return BarTooltipItem(
                        '${doc.doctorName}\n${doc.totalOrders} órdenes\n\$${NumberFormatter.decimalPattern(rod.toY)}',
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
                        if (idx >= 0 && idx < chartItems.length) {
                          final name = chartItems[idx].doctorName;
                          final shortName = name.length > 12
                              ? '${name.substring(0, 10)}..'
                              : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              shortName,
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
                      reservedSize: 64,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '\$${NumberFormatter.decimalPattern(value.toInt())}',
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
                    color: theme.colorScheme.outlineVariant.withAlpha(40),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chartItems.length, (idx) {
                  final doc = chartItems[idx];
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: doc.totalRevenue / 100,
                        color: idx == 0
                            ? ColorPalette.primary
                            : ColorPalette.primaryFixedDim,
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
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

  Widget _buildDoctorsTable(ThemeData theme, List<DoctorOrderItem> doctors) {
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
              Icon(Icons.format_list_numbered, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Ranking Completo de Médicos Prescriptores',
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
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Médico', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Especialidad', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Órdenes Emitidas', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ingresos Generados', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(doctors.length, (index) {
                final doc = doctors[index];
                return DataRow(
                  cells: [
                    DataCell(
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: index < 3
                            ? ColorPalette.primary.withAlpha(40)
                            : theme.colorScheme.surfaceContainerHigh,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: index < 3
                                ? ColorPalette.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      doc.doctorName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(doc.specialty.isEmpty ? '—' : doc.specialty)),
                    DataCell(Text('${doc.totalOrders} órdenes')),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(doc.totalRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    )),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DoctorKpiCard({
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
