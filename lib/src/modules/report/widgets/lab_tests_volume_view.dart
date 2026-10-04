import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/report_cubit/report_cubit.dart';

class LabTestsVolumeView extends StatelessWidget {
  final LabTestsVolumeReportResponse report;

  const LabTestsVolumeView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportCubit = context.read<ReportCubit>();
    final isOrders = report.source == 'orders';
    final summary = report.summary;
    final topTests = summary.topTests;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de Fuente: Órdenes vs Cotizaciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Análisis por Demanda Clínica',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'orders',
                    label: Text('Órdenes Clínicas'),
                    icon: Icon(Icons.receipt_long, size: 16),
                  ),
                  ButtonSegment<String>(
                    value: 'quotations',
                    label: Text('Cotizaciones'),
                    icon: Icon(Icons.request_quote, size: 16),
                  ),
                ],
                selected: {report.source},
                onSelectionChanged: (selection) {
                  reportCubit.setLabTestsSource(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tarjetas KPI
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _VolumeKpiCard(
                title: isOrders ? 'Total Solicitudes' : 'Total Cotizaciones',
                value: summary.totalTestsCount.toString(),
                subtitle: 'Pruebas y perfiles indicados',
                icon: Icons.science,
                color: ColorPalette.primary,
              ),
              _VolumeKpiCard(
                title: isOrders ? 'Ingresos Generados' : 'Presupuesto Estimado',
                value: NumberFormatter.convertToMoneyLike(summary.totalRevenue),
                subtitle: 'Volumen monetario demandado',
                icon: Icons.monetization_on,
                color: const Color(0xFF2E7D32),
              ),
              _VolumeKpiCard(
                title: 'Variedad de Catálogo',
                value: topTests.length.toString(),
                subtitle: 'Ítems destacados en el período',
                icon: Icons.category,
                color: ColorPalette.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (topTests.isEmpty)
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
                      Icons.science_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se registraron estudios clínicos para esta selección.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Gráfico BarChart destacando si es Pack vs Individual
            _buildChartCard(theme, topTests),
            const SizedBox(height: 24),

            // Tabla de volumen
            _buildTestsTable(theme, topTests),
          ],
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, List<LabTestVolumeItem> tests) {
    final chartItems = tests.take(8).toList();
    final maxOrders = chartItems.isEmpty
        ? 10.0
        : chartItems
            .map((t) => t.timesOrdered.toDouble())
            .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxOrders > 0 ? maxOrders * 1.25 : 10.0;

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
              Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Top Pruebas y Perfiles por Frecuencia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Leyenda Pack vs Individual
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ColorPalette.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Individual', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ColorPalette.tertiary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Pack / Perfil', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cantidad de veces que fue solicitado cada análisis o paquete de estudio.',
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
                      final item = chartItems[group.x.toInt()];
                      final tipo = item.isPack ? 'Pack' : 'Prueba Individual';
                      return BarTooltipItem(
                        '${item.name}\n($tipo)\n${item.timesOrdered} veces\n${NumberFormatter.convertToMoneyLike(item.totalRevenue)}',
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
                          final name = chartItems[idx].name;
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
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
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
                  final item = chartItems[idx];
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: item.timesOrdered.toDouble(),
                        color: item.isPack
                            ? ColorPalette.tertiary
                            : ColorPalette.primary,
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

  Widget _buildTestsTable(ThemeData theme, List<LabTestVolumeItem> tests) {
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
              Icon(Icons.table_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Desglose Detallado de Demanda',
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
                DataColumn(label: Text('Nombre de Prueba / Pack', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Veces Solicitado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Ingreso Generado', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: tests.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.isPack
                              ? ColorPalette.tertiaryContainer.withAlpha(40)
                              : ColorPalette.primaryFixed.withAlpha(80),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.isPack ? 'PACK' : 'INDIVIDUAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.isPack
                                ? ColorPalette.tertiary
                                : ColorPalette.primary,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(item.category.isEmpty ? 'General' : item.category)),
                    DataCell(Text('${item.timesOrdered} veces')),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(item.totalRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    )),
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

class _VolumeKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _VolumeKpiCard({
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
