import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

import '../../../../config/app_theme.dart';
import '../../../cubits/app_session_cubit/app_session_cubit.dart';
import '../../../cubits/cash_movement_cubit/read_cash_movements_cubit.dart';
import '../../../cubits/cash_movement_cubit/write_cash_movements_cubit.dart';
import 'cash_movement_dialog.dart';

class CashMovementsListDialog extends StatefulWidget {
  final CashShiftInDb shift;

  const CashMovementsListDialog({
    super.key,
    required this.shift,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CashShiftInDb shift,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CashMovementsListDialog(shift: shift),
    );
  }

  @override
  State<CashMovementsListDialog> createState() =>
      _CashMovementsListDialogState();
}

class _CashMovementsListDialogState extends State<CashMovementsListDialog> {
  bool _hasModified = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMovements();
    });
  }

  void _loadMovements() {
    if (!mounted) return;
    context.read<ReadCashMovementCubit>().getAll(
          CashMovementQueryParams(
            shiftId: widget.shift.id,
            limit: 100,
          ),
        );
  }

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

  Future<void> _confirmCancelMovement(CashMovementInDb movement) async {
    final theme = Theme.of(context);
    final isIncome = movement.isIncome;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: theme.colorScheme.error, size: 26),
            const SizedBox(width: 10),
            const Text('Confirmar Anulación'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de anular este ${isIncome ? "ingreso" : "egreso"}?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withAlpha(120),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Concepto: ${movement.concept}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Monto: ',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${isIncome ? "+" : "-"}${movement.formattedAmount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isIncome
                                ? Colors.green.shade800
                                : ColorPalette.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Método: ${movement.paymentMethodLabel}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withAlpha(100),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción revertirá el saldo del turno automáticamente y generará un contra-asiento compensatorio en el Kardex contable.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Sí, Anular Movimiento'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);
    final writeCubit = context.read<WriteCashMovementCubit>();
    await writeCubit.delete(movement.id);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    final writeState = writeCubit.state;
    if (writeState is WriteCashMovementError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No fue posible anular: ${writeState.message}'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    } else {
      _hasModified = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Movimiento anulado exitosamente. Saldo revertido en turno y Kardex.',
          ),
          backgroundColor: Colors.green.shade800,
        ),
      );
      // Actualizar sesión activa
      await context.read<AppSessionCubit>().fetchActiveShift();
      _loadMovements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOpen = widget.shift.isOpen;
    final shortId = widget.shift.id.length >= 8
        ? widget.shift.id.substring(0, 8)
        : widget.shift.id;

    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _hasModified) {
          // notifica al llamador
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Movimientos del Turno #$shortId',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOpen
                                      ? Colors.green.shade50
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isOpen
                                        ? Colors.green.shade600
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  isOpen ? 'ABIERTO' : 'CERRADO',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isOpen
                                        ? Colors.green.shade800
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Historial de entradas y salidas libres registradas bajo este turno',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refrescar movimientos',
                      onPressed: _isProcessing ? null : _loadMovements,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cerrar',
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(_hasModified),
                    ),
                  ],
                ),
              ),

              // Body Content
              Expanded(
                child: BlocBuilder<ReadCashMovementCubit, ReadCashMovementState>(
                  builder: (context, state) {
                    List<CashMovementInDb> movements = [];
                    bool isLoading = false;

                    if (state is ReadCashMovementLoading) {
                      isLoading = true;
                    } else if (state is ReadCashMovementSuccess) {
                      movements = state.items
                          .where((m) => m.shiftId == widget.shift.id)
                          .toList();
                    } else if (state is ReadCashMovementRefreshing) {
                      movements = state.items
                          .where((m) => m.shiftId == widget.shift.id)
                          .toList();
                      isLoading = true;
                    }

                    // Calcular KPIs de movimientos
                    final totalIncomesCents = movements
                        .where((m) => m.isIncome)
                        .fold<int>(0, (sum, m) => sum + m.amount);
                    final totalWithdrawalsCents = movements
                        .where((m) => m.isWithdrawal)
                        .fold<int>(0, (sum, m) => sum + m.amount);
                    final netCents =
                        totalIncomesCents - totalWithdrawalsCents;

                    return Column(
                      children: [
                        // Metric Bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  label: 'Total Ingresos Libres',
                                  amount:
                                      '+\$${(totalIncomesCents / 100).toStringAsFixed(2)}',
                                  icon: Icons.arrow_downward_rounded,
                                  color: Colors.green.shade800,
                                  bgColor: Colors.green.shade50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  label: 'Total Egresos / Retiros',
                                  amount:
                                      '-\$${(totalWithdrawalsCents / 100).toStringAsFixed(2)}',
                                  icon: Icons.arrow_upward_rounded,
                                  color: ColorPalette.error,
                                  bgColor: Colors.red.shade50,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _MetricCard(
                                  label: 'Impacto Neto en Caja',
                                  amount:
                                      '${netCents >= 0 ? "+" : ""}\$${(netCents / 100).toStringAsFixed(2)}',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: netCents >= 0
                                      ? theme.colorScheme.primary
                                      : ColorPalette.error,
                                  bgColor: theme.colorScheme.surfaceContainerHigh,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Movements List or Empty State
                        Expanded(
                          child: isLoading && movements.isEmpty
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : movements.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            size: 48,
                                            color: theme
                                                .colorScheme.onSurfaceVariant
                                                .withAlpha(120),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No hay movimientos registrados',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isOpen
                                                ? 'Registra un ingreso o egreso libre con el botón inferior.'
                                                : 'Este turno no tuvo movimientos libres.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      itemCount: movements.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final movement = movements[index];
                                        return _MovementTile(
                                          movement: movement,
                                          shiftIsOpen: isOpen,
                                          formattedTime: _formatDateTime(
                                              movement.createdAt),
                                          onCancel: () =>
                                              _confirmCancelMovement(movement),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Footer Actions
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                ),
                child: Row(
                  children: [
                    if (!isOpen)
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            'Turno cerrado: los movimientos son de solo lectura contable.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () => Navigator.of(context).pop(_hasModified),
                      child: const Text('Cerrar'),
                    ),
                    if (isOpen) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo Movimiento'),
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                final res = await CashMovementDialog.show(
                                  context,
                                  shift: widget.shift,
                                );
                                if (res != null) {
                                  _hasModified = true;
                                  _loadMovements();
                                }
                              },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
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

class _MovementTile extends StatelessWidget {
  final CashMovementInDb movement;
  final bool shiftIsOpen;
  final String formattedTime;
  final VoidCallback onCancel;

  const _MovementTile({
    required this.movement,
    required this.shiftIsOpen,
    required this.formattedTime,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = movement.isIncome;
    final color = isIncome ? Colors.green.shade800 : ColorPalette.error;
    final bgColor = isIncome ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(90),
        ),
      ),
      child: Row(
        children: [
          // Circle Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        movement.typeLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Method Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(60),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        movement.paymentMethodLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  movement.concept,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 13, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      formattedTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.person_outline,
                        size: 13, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      movement.performedBy.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+" : "-"}${movement.formattedAmount}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              if (shiftIsOpen)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: theme.colorScheme.error,
                  tooltip: 'Anular este movimiento',
                  visualDensity: VisualDensity.compact,
                  onPressed: onCancel,
                )
              else
                Tooltip(
                  message: 'Turno cerrado: no se puede anular',
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
