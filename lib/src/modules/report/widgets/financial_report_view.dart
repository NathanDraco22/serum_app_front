import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';

class FinancialReportView extends StatelessWidget {
  final FinancialReportResponse report;

  const FinancialReportView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = report.summary;

    final totalCash = summary.paymentMethods.cash;
    final totalCard = summary.paymentMethods.card;
    final totalTransfer = summary.paymentMethods.transfer;
    final totalPayments = totalCash + totalCard + totalTransfer;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas KPI Principales
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _KpiCard(
                    title: 'Total Facturado',
                    value: NumberFormatter.convertToMoneyLike(summary.totalBilled),
                    subtitle: '${summary.ordersCount} órdenes clínicas',
                    icon: Icons.receipt_long,
                    color: ColorPalette.primary,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : 260,
                  ),
                  _KpiCard(
                    title: 'Cobranza Real (Kardex)',
                    value: NumberFormatter.convertToMoneyLike(summary.totalCollected),
                    subtitle: '${summary.transactionsCount} transacciones',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF2E7D32),
                    width: isWide ? (constraints.maxWidth - 48) / 4 : 260,
                  ),
                  _KpiCard(
                    title: 'Cartera por Cobrar',
                    value: NumberFormatter.convertToMoneyLike(summary.pendingReceivables),
                    subtitle: 'Saldos pendientes de pago',
                    icon: Icons.pending_actions,
                    color: summary.pendingReceivables > 0
                        ? ColorPalette.tertiary
                        : theme.colorScheme.outline,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : 260,
                  ),
                  _KpiCard(
                    title: 'Cumplimiento Cobro',
                    value: summary.totalBilled > 0
                        ? '${((summary.totalCollected / summary.totalBilled) * 100).clamp(0, 100).toStringAsFixed(1)}%'
                        : '100%',
                    subtitle: 'Efectividad de cobranza',
                    icon: Icons.trending_up,
                    color: ColorPalette.primaryContainer,
                    width: isWide ? (constraints.maxWidth - 48) / 4 : 260,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Gráficos lado a lado o apilados
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildBarChartCard(theme, summary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: _buildPieChartCard(
                        theme,
                        totalCash,
                        totalCard,
                        totalTransfer,
                        totalPayments,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildBarChartCard(theme, summary),
                  const SizedBox(height: 16),
                  _buildPieChartCard(
                    theme,
                    totalCash,
                    totalCard,
                    totalTransfer,
                    totalPayments,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Desglose por Sucursales (si aplica)
          if (report.byBranch.isNotEmpty) _buildBranchBreakdownTable(theme),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, FinancialSummaryReport summary) {
    final billed = summary.totalBilled / 100;
    final collected = summary.totalCollected / 100;
    final pending = summary.pendingReceivables / 100;

    final maxY = [billed, collected, pending].reduce((a, b) => a > b ? a : b);
    final effectiveMaxY = maxY > 0 ? maxY * 1.2 : 100.0;

    final labels = ['Facturado', 'Cobrado Real', 'Pendiente'];
    final colors = [
      ColorPalette.primary,
      const Color(0xFF2E7D32),
      ColorPalette.tertiary,
    ];

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
                'Comparativa Financiera Global',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Contraste entre el volumen facturado en órdenes, el recaudo efectivo en Kardex y los saldos por cobrar.',
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
                maxY: effectiveMaxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => ColorPalette.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${labels[group.x.toInt()]}\n\$${NumberFormatter.decimalPattern(rod.toY)}',
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[idx],
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors[idx],
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
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: billed,
                        color: colors[0],
                        width: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: collected,
                        color: colors[1],
                        width: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: pending,
                        color: colors[2],
                        width: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    ThemeData theme,
    int cash,
    int card,
    int transfer,
    int total,
  ) {
    final cashPct = total > 0 ? (cash / total) * 100 : 0.0;
    final cardPct = total > 0 ? (card / total) * 100 : 0.0;
    final transPct = total > 0 ? (transfer / total) * 100 : 0.0;

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
              Icon(Icons.pie_chart, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Métodos de Pago',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Distribución de recaudación efectiva en caja.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            const SizedBox(
              height: 240,
              child: Center(
                child: Text('Sin recaudación en este período'),
              ),
            )
          else ...[
            SizedBox(
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: [
                    if (cash > 0)
                      PieChartSectionData(
                        value: cash.toDouble(),
                        title: '${cashPct.toStringAsFixed(0)}%',
                        color: const Color(0xFF2E7D32),
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (card > 0)
                      PieChartSectionData(
                        value: card.toDouble(),
                        title: '${cardPct.toStringAsFixed(0)}%',
                        color: ColorPalette.primary,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (transfer > 0)
                      PieChartSectionData(
                        value: transfer.toDouble(),
                        title: '${transPct.toStringAsFixed(0)}%',
                        color: ColorPalette.tertiary,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PaymentLegendRow(
              color: const Color(0xFF2E7D32),
              title: 'Efectivo',
              amount: NumberFormatter.convertToMoneyLike(cash),
              pct: '${cashPct.toStringAsFixed(1)}%',
            ),
            const Divider(height: 12),
            _PaymentLegendRow(
              color: ColorPalette.primary,
              title: 'Tarjeta',
              amount: NumberFormatter.convertToMoneyLike(card),
              pct: '${cardPct.toStringAsFixed(1)}%',
            ),
            const Divider(height: 12),
            _PaymentLegendRow(
              color: ColorPalette.tertiary,
              title: 'Transferencia',
              amount: NumberFormatter.convertToMoneyLike(transfer),
              pct: '${transPct.toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchBreakdownTable(ThemeData theme) {
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
              Icon(Icons.storefront, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Desglose Financiero por Sucursal',
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
                DataColumn(label: Text('Sucursal', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Órdenes', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Facturado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Cobrado Real', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pendiente', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Efectivo', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Tarjeta', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Transferencia', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: report.byBranch.map((branch) {
                return DataRow(
                  cells: [
                    DataCell(Text(branch.branchName.isEmpty ? branch.branchId : branch.branchName)),
                    DataCell(Text(branch.ordersCount.toString())),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(branch.totalBilled))),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(branch.totalCollected),
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                    )),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(branch.pendingReceivables),
                      style: TextStyle(
                        color: branch.pendingReceivables > 0 ? ColorPalette.tertiary : null,
                        fontWeight: branch.pendingReceivables > 0 ? FontWeight.bold : null,
                      ),
                    )),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(branch.paymentMethods.cash))),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(branch.paymentMethods.card))),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(branch.paymentMethods.transfer))),
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

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
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

class _PaymentLegendRow extends StatelessWidget {
  final Color color;
  final String title;
  final String amount;
  final String pct;

  const _PaymentLegendRow({
    required this.color,
    required this.title,
    required this.amount,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          amount,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          '($pct)',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}
