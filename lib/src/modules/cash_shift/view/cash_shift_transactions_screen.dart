import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_transaction_cubit/read_cash_transactions_cubit.dart';
import '../widgets/cash_shift_transactions_list.dart';

/// Sub-vista de detalle del turno: Kardex contable completo de solo lectura.
class CashShiftTransactionsScreen extends StatefulWidget {
  final String shiftId;
  final CashShiftInDb? shift;

  const CashShiftTransactionsScreen({
    super.key,
    required this.shiftId,
    this.shift,
  });

  @override
  State<CashShiftTransactionsScreen> createState() => _CashShiftTransactionsScreenState();
}

class _CashShiftTransactionsScreenState extends State<CashShiftTransactionsScreen> {
  CashShiftInDb? _shift;
  bool _isResolvingShift = false;

  @override
  void initState() {
    super.initState();
    _shift = widget.shift;
    if (_shift == null) {
      _isResolvingShift = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadShift());
    }
  }

  Future<void> _loadShift() async {
    try {
      final shift = await context.read<CashShiftsRepository>().getCashShiftById(widget.shiftId);
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _isResolvingShift = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isResolvingShift = false);
    }
  }

  Future<void> _refreshShift() async {
    try {
      final shift = await context.read<CashShiftsRepository>().getCashShiftById(widget.shiftId);
      if (!mounted || shift == null) return;
      setState(() => _shift = shift);
    } catch (_) {
      // La cabecera conserva el último dato disponible si falla la recarga.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolvingShift) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transacciones del Turno')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final branchId = _shift?.branchId ?? context.read<AppSessionCubit>().currentBranchId;

    return BlocProvider<ReadCashTransactionCubit>(
      create: (context) =>
          ReadCashTransactionCubit(
            cashTransactionsRepository: RepositoryProvider.of<CashTransactionsRepository>(context),
          )..getAll(
            CashTransactionQueryParams(
              branchId: branchId,
              shiftId: widget.shiftId,
              limit: 0,
            ),
          ),
      child: _RootScaffold(
        shift: _shift,
        shiftId: widget.shiftId,
        onRefreshShift: _refreshShift,
      ),
    );
  }
}

class _RootScaffold extends StatelessWidget {
  final CashShiftInDb? shift;
  final String shiftId;
  final Future<void> Function() onRefreshShift;

  const _RootScaffold({
    required this.shift,
    required this.shiftId,
    required this.onRefreshShift,
  });

  String get _shortId => shiftId.length >= 8 ? shiftId.substring(0, 8) : shiftId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transacciones del Turno #$_shortId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (shift != null)
              Text(
                '${shift!.userName ?? 'Custodio'} • ${shift!.branchName ?? shift!.branchId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refrescar transacciones',
            onPressed: () async {
              context.read<ReadCashTransactionCubit>().getAll(
                CashTransactionQueryParams(
                  branchId: shift?.branchId,
                  shiftId: shiftId,
                  limit: 0,
                ),
              );
              await onRefreshShift();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _Body(shift: shift, shiftId: shiftId),
    );
  }
}

class _Body extends StatelessWidget {
  final CashShiftInDb? shift;
  final String shiftId;

  const _Body({required this.shift, required this.shiftId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (shift != null) _ShiftSummaryHeader(shift: shift!),
        Expanded(
          child: BlocBuilder<ReadCashTransactionCubit, ReadCashTransactionState>(
            builder: (context, state) {
              if (state is ReadCashTransactionLoading || state is ReadCashTransactionInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ReadCashTransactionError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error al cargar transacciones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<ReadCashTransactionCubit>().getAll(
                              CashTransactionQueryParams(
                                branchId: shift?.branchId,
                                shiftId: shiftId,
                                limit: 0,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final success = state as ReadCashTransactionSuccess;
              final items = success.items;
              final isRefreshing = state is ReadCashTransactionRefreshing;

              final content = items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay transacciones registradas para este turno',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CashShiftTransactionsList(items: items);

              return Column(
                children: [
                  if (isRefreshing) const LinearProgressIndicator(minHeight: 2),
                  Expanded(child: content),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShiftSummaryHeader extends StatelessWidget {
  final CashShiftInDb shift;

  const _ShiftSummaryHeader({required this.shift});

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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : theme.colorScheme.surfaceContainerHighest,
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
                      color: isOpen ? Colors.green.shade800 : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'ABIERTO' : 'CERRADO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOpen ? Colors.green.shade800 : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoItem(
                icon: Icons.person_outline,
                label: 'Custodio',
                value: shift.userName?.isNotEmpty == true ? shift.userName! : shift.userId,
              ),
              _InfoItem(
                icon: Icons.store_outlined,
                label: 'Sucursal',
                value: shift.branchName?.isNotEmpty == true ? shift.branchName! : shift.branchId,
              ),
              _InfoItem(
                icon: Icons.login_rounded,
                label: 'Apertura',
                value: _formatDateTime(shift.openedAt),
              ),
              if (!isOpen && shift.closedAt != null)
                _InfoItem(
                  icon: Icons.logout_rounded,
                  label: 'Cierre',
                  value: _formatDateTime(shift.closedAt),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryMetric(
                label: 'Fondo inicial',
                amount: shift.initialBalance,
                icon: Icons.savings_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              _SummaryMetric(
                label: 'Efectivo cobrado',
                amount: shift.cashBalance,
                icon: Icons.payments_outlined,
                color: Colors.green.shade700,
              ),
              _SummaryMetric(
                label: 'Tarjeta',
                amount: shift.cardBalance,
                icon: Icons.credit_card,
                color: Colors.blue.shade700,
              ),
              _SummaryMetric(
                label: 'Transferencia',
                amount: shift.transferBalance,
                icon: Icons.swap_horiz_rounded,
                color: Colors.purple.shade700,
              ),
              _SummaryMetric(
                label: 'Saldo del turno',
                amount: shift.totalBalance,
                icon: Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary,
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
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

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  final Color color;
  final bool isBold;

  const _SummaryMetric({
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
      width: 160,
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
            NumberFormatter.currencyFormat.format(amount / 100.0),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
