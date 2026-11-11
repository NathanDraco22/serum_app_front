import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_router.dart';
import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../widgets/dialogs/viewers/cash_shift_viewer.dart';
import '../widgets/cash_movements_list_dialog.dart';
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
    final sessionCubit = context.watch<AppSessionCubit>();
    final isOpen = shift.isOpen;
    final shortId = shift.id.length >= 8 ? shift.id.substring(0, 8) : shift.id;

    final resolvedBranch = sessionCubit.getBranchById(shift.branchId);
    final branchName = resolvedBranch?.displayName ??
        (shift.branchName?.isNotEmpty == true
            ? shift.branchName!
            : (shift.branchId.isNotEmpty ? shift.branchId : 'Sucursal'));

    final custodianName = shift.userName?.isNotEmpty == true
        ? shift.userName!
        : (shift.userId == sessionCubit.user?.id
              ? sessionCubit.user?.name ?? 'Usuario'
              : (shift.userId.isNotEmpty ? shift.userId : 'Sistema'));

    final activeShiftId = sessionCubit.state.activeShift?.id;
    final isActiveShift = isOpen && shift.id == activeShiftId;
    final isShiftInCurrentBranch = shift.branchId == sessionCubit.currentBranchId;

    final cardColor = isActiveShift
        ? Color.alphaBlend(
            theme.brightness == Brightness.dark
                ? Colors.amber.shade900.withAlpha(35)
                : Colors.amber.shade50.withAlpha(170),
            theme.colorScheme.surfaceContainerLow,
          )
        : theme.colorScheme.surfaceContainerLow;

    final borderColor = isActiveShift
        ? Colors.amber.shade600
        : (isOpen ? theme.colorScheme.primary.withAlpha(120) : theme.colorScheme.outlineVariant);

    final borderWidth = isActiveShift ? 2.0 : (isOpen ? 1.5 : 1.0);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status, ID and active/current-user badges
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? Colors.green.shade50
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isOpen ? Colors.green.shade600 : theme.colorScheme.outlineVariant,
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
                    // Shift ID
                    Text(
                      'Turno #$shortId',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isActiveShift)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade600),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'TURNO ACTUAL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                ),
                const SizedBox(height: 12),

                // Acciones del turno
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Kardex contable completo del turno (solo lectura)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                      label: const Text('Transacciones'),
                      onPressed: () {
                        context.push(
                          AppRouter.cashShiftTransactionsPath(shift.id),
                          extra: shift,
                        );
                      },
                    ),
                    // Ver movimientos libres (disponible para consultar y auditar cualquier turno)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.swap_vert_rounded, size: 16),
                      label: const Text('Movimientos'),
                      onPressed: () async {
                        final res = await CashMovementsListDialog.show(
                          context,
                          shift: shift,
                        );
                        if (res == true) {
                          onShiftUpdated?.call();
                        }
                      },
                    ),
                    // Imprimir / Exportar Comprobante de Turno y Arqueo en PDF
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Imprimir / PDF'),
                      onPressed: () {
                        showCashShiftViewerDialog(context, shift);
                      },
                    ),
                    // Corte y arqueo: solo turno abierto del usuario actual
                    if (isOpen && isCurrentUser)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.lock_clock_rounded, size: 16),
                        label: const Text('Corte y Arqueo'),
                        onPressed: isShiftInCurrentBranch
                            ? () async {
                                final res = await CashShiftCloseDialog.show(context, shift);
                                if (res != null) {
                                  onShiftUpdated?.call();
                                  if (context.mounted) {
                                    showCashShiftViewerDialog(context, res);
                                  }
                                }
                              }
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metadata: Custodian, Branch, Opened At, Closed At
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.person_outline,
                      label: 'Custodio',
                      value: custodianName,
                    ),
                    _InfoChip(
                      icon: Icons.store_outlined,
                      label: 'Sucursal',
                      value: branchName,
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
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Financial Metrics Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 650;
                    final boxWidth = isNarrow ? constraints.maxWidth : 160.0;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MetricBox(
                          width: boxWidth,
                          label: 'Fondo Inicial',
                          amount: NumberFormatter.currencyFormat.format(shift.initialBalanceDouble),
                          icon: Icons.savings_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        _MetricBox(
                          width: boxWidth,
                          label: 'Efectivo Cobrado',
                          amount:
                              '+${NumberFormatter.currencyFormat.format(shift.cashBalanceDouble)}',
                          icon: Icons.payments_outlined,
                          color: Colors.green.shade700,
                        ),
                        _MetricBox(
                          width: boxWidth,
                          label: 'Tarjeta',
                          amount: NumberFormatter.currencyFormat.format(shift.cardBalanceDouble),
                          icon: Icons.credit_card,
                          color: Colors.blue.shade700,
                        ),
                        _MetricBox(
                          width: boxWidth,
                          label: 'Transferencia',
                          amount: NumberFormatter.currencyFormat.format(
                            shift.transferBalanceDouble,
                          ),
                          icon: Icons.swap_horiz_rounded,
                          color: Colors.purple.shade700,
                        ),
                        _MetricBox(
                          width: boxWidth,
                          label: 'Total Efectivo Gaveta',
                          amount: NumberFormatter.currencyFormat.format(
                            shift.totalCashExpectedDouble,
                          ),
                          icon: Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.primary,
                          isBold: true,
                        ),
                      ],
                    );
                  },
                ),

                // Desglose de Transferencias por Banco si existen
                if (shift.bankTransfers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 15, color: Colors.purple.shade800),
                        const SizedBox(width: 8),
                        Text(
                          'Bancos: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: shift.bankTransfers.entries.map((e) {
                              final amt = NumberFormatter.convertToMoneyLike(e.value);
                              return Text(
                                '${e.key}: $amt',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade900,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Arqueo Result (si está cerrado)
                if (!isOpen && shift.declaredCash != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _getDiffColor(shift.differenceDouble ?? 0).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getDiffColor(shift.differenceDouble ?? 0).withAlpha(100),
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
                                'Arqueo: Efectivo Declarado ${NumberFormatter.currencyFormat.format(shift.declaredCashDouble ?? 0.0)}',
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getDiffColor(shift.differenceDouble ?? 0).withAlpha(40),
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
          if (isActiveShift)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: Colors.amber.shade600),
            ),
        ],
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
    final formatted = NumberFormatter.currencyFormat.format(diff);
    if (diff < 0) {
      return 'Faltante en gaveta de $formatted.';
    }
    return 'Sobrante en gaveta de +$formatted.';
  }

  String _formatDiffText(double diff) {
    if (diff == 0.0) {
      return 'Cuadrado (${NumberFormatter.convertToMoneyLike(0)})';
    }
    final formatted = NumberFormatter.currencyFormat.format(diff);
    if (diff < 0) return 'Faltante: $formatted';
    return 'Sobrante: +$formatted';
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
