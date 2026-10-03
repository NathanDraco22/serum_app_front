import 'package:flutter/material.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../widgets/cash_shift_close_dialog.dart';

class CashShiftCard extends StatelessWidget {
  final CashShiftInDb shift;
  final bool isCurrentUser;
  final VoidCallback? onShiftUpdated;

  const CashShiftCard({
    super.key,
    required this.shift,
    this.isCurrentUser = false,
    this.onShiftUpdated,
  });

  String _formatDateTime(int? timestamp) {
    if (timestamp == null || timestamp <= 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = shift.isOpen;
    final shortId = shift.id.length >= 8 ? shift.id.substring(0, 8) : shift.id;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOpen
              ? theme.colorScheme.primary.withAlpha(120)
              : theme.colorScheme.outlineVariant,
          width: isOpen ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status badge, ID, Custodian, Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.shade50
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOpen
                          ? Colors.green.shade600
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                        size: 14,
                        color: isOpen
                            ? Colors.green.shade800
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? 'ABIERTO' : 'CERRADO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isOpen
                              ? Colors.green.shade800
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Shift ID
                Text(
                  'Turno #$shortId',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Mi Turno',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // If open and is current user, action to close
                if (isOpen && isCurrentUser)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.lock_clock_rounded, size: 16),
                    label: const Text('Corte y Arqueo'),
                    onPressed: () async {
                      final res =
                          await CashShiftCloseDialog.show(context, shift);
                      if (res != null) {
                        onShiftUpdated?.call();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata: Custodian, Opened At, Closed At
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.person_outline,
                  label: 'Custodio',
                  value: shift.userId.isNotEmpty ? shift.userId : 'Sistema',
                ),
                _InfoChip(
                  icon: Icons.login_rounded,
                  label: 'Apertura',
                  value: _formatDateTime(shift.openedAt),
                ),
                if (!isOpen && shift.closedAt != null)
                  _InfoChip(
                    icon: Icons.logout_rounded,
                    label: 'Cierre',
                    value: _formatDateTime(shift.closedAt),
                  ),
                if (shift.branchId.isNotEmpty)
                  _InfoChip(
                    icon: Icons.store_outlined,
                    label: 'Sucursal',
                    value: shift.branchId,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Financial Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _MetricBox(
                      width: isNarrow ? constraints.maxWidth : 180,
                      label: 'Fondo Inicial',
                      amount:
                          '\$${shift.initialBalanceDouble.toStringAsFixed(2)}',
                      icon: Icons.savings_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    _MetricBox(
                      width: isNarrow ? constraints.maxWidth : 180,
                      label: 'Efectivo Cobrado',
                      amount: '+\$${shift.cashBalanceDouble.toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                      color: Colors.green.shade700,
                    ),
                    _MetricBox(
                      width: isNarrow ? constraints.maxWidth : 180,
                      label: 'Total Efectivo Esperado',
                      amount:
                          '\$${shift.totalCashExpectedDouble.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                      isBold: true,
                    ),
                    if (shift.cardBalance > 0 || shift.transferBalance > 0)
                      _MetricBox(
                        width: isNarrow ? constraints.maxWidth : 180,
                        label: 'Tarjetas / Transf.',
                        amount:
                            '\$${(shift.cardBalanceDouble + shift.transferBalanceDouble).toStringAsFixed(2)}',
                        icon: Icons.credit_card,
                        color: theme.colorScheme.secondary,
                      ),
                  ],
                );
              },
            ),

            // Arqueo Result (si está cerrado)
            if (!isOpen && shift.declaredCash != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getDiffColor(shift.differenceDouble ?? 0)
                      .withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getDiffColor(shift.differenceDouble ?? 0)
                        .withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getDiffIcon(shift.differenceDouble ?? 0),
                      color: _getDiffColor(shift.differenceDouble ?? 0),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arqueo: Efectivo Declarado \$${(shift.declaredCashDouble ?? 0.0).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDiffDescription(shift.differenceDouble ?? 0),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Difference Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDiffColor(shift.differenceDouble ?? 0)
                            .withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDiffText(shift.differenceDouble ?? 0),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getDiffColor(shift.differenceDouble ?? 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Notes
            if (shift.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Notas: ${shift.notes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDiffColor(double diff) {
    if (diff == 0.0) return Colors.green.shade700;
    if (diff < 0) return ColorPalette.error;
    return ColorPalette.primary;
  }

  IconData _getDiffIcon(double diff) {
    if (diff == 0.0) return Icons.check_circle_outline;
    if (diff < 0) return Icons.warning_amber_rounded;
    return Icons.info_outline;
  }

  String _getDiffDescription(double diff) {
    if (diff == 0.0) return 'El conteo físico cuadró exactamente con el sistema.';
    if (diff < 0) {
      return 'Faltante en gaveta de -\$${(-diff).toStringAsFixed(2)}.';
    }
    return 'Sobrante en gaveta de +\$${diff.toStringAsFixed(2)}.';
  }

  String _formatDiffText(double diff) {
    if (diff == 0.0) return 'Cuadrado (\$0.00)';
    if (diff < 0) return 'Faltante: -\$${(-diff).toStringAsFixed(2)}';
    return 'Sobrante: +\$${diff.toStringAsFixed(2)}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final double width;
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isBold;

  const _MetricBox({
    required this.width,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
