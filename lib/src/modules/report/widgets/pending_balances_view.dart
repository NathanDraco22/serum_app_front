import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';

class PendingBalancesView extends StatelessWidget {
  final PendingBalancesReportResponse report;

  const PendingBalancesView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = report.summary;

    // Recopilar todas las órdenes deudoras de todas las sucursales o de la sucursal activa
    final allOrders = <PendingBalanceItem>[];
    for (final b in report.byBranch) {
      allOrders.addAll(b.orders);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas KPI de Cartera
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _PendingKpiCard(
                title: 'Total Cartera Pendiente',
                value: NumberFormatter.convertToMoneyLike(summary.totalPendingAmount),
                subtitle: 'Monto adeudado por pacientes',
                icon: Icons.money_off,
                color: summary.totalPendingAmount > 0
                    ? ColorPalette.error
                    : const Color(0xFF2E7D32),
              ),
              _PendingKpiCard(
                title: 'Órdenes con Saldo Deudor',
                value: summary.ordersCount.toString(),
                subtitle: 'Pacientes con saldo pendiente',
                icon: Icons.pending_actions,
                color: ColorPalette.tertiary,
              ),
              _PendingKpiCard(
                title: 'Promedio por Deudor',
                value: summary.ordersCount > 0
                    ? NumberFormatter.convertToMoneyLike(
                        (summary.totalPendingAmount / summary.ordersCount).round(),
                      )
                    : '\$0.00',
                subtitle: 'Ticket de deuda promedio',
                icon: Icons.pie_chart_outline,
                color: ColorPalette.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (allOrders.isEmpty)
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
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Excelente! No hay órdenes con saldo pendiente en este rango.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildBalancesTable(theme, allOrders),
        ],
      ),
    );
  }

  Widget _buildBalancesTable(ThemeData theme, List<PendingBalanceItem> orders) {
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
              Icon(Icons.list_alt, color: ColorPalette.error),
              const SizedBox(width: 8),
              Text(
                'Listado de Cuentas por Cobrar',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${orders.length} órdenes pendientes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
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
                DataColumn(label: Text('ID Orden', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Paciente', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Total Orden', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Abonado', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Pendiente', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Antigüedad (Días)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: orders.map((o) {
                final isOverdue = o.daysPending > 30;
                final isWarning = o.daysPending > 15;

                return DataRow(
                  cells: [
                    DataCell(Text(
                      o.orderId.length > 8
                          ? '#${o.orderId.substring(o.orderId.length - 6)}'
                          : '#${o.orderId}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    DataCell(Text(
                      o.patientName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(o.patientPhone.isEmpty ? '—' : o.patientPhone)),
                    DataCell(Text(NumberFormatter.convertToMoneyLike(o.totalPrice))),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(o.paidAmount),
                      style: const TextStyle(color: Color(0xFF2E7D32)),
                    )),
                    DataCell(Text(
                      NumberFormatter.convertToMoneyLike(o.pendingAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.error,
                      ),
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? ColorPalette.errorContainer
                              : (isWarning
                                  ? ColorPalette.tertiaryContainer.withAlpha(40)
                                  : theme.colorScheme.surfaceContainerHigh),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${o.daysPending} días',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? ColorPalette.onErrorContainer
                                : (isWarning
                                    ? ColorPalette.tertiary
                                    : theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
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

class _PendingKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PendingKpiCard({
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
